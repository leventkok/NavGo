package router

import (
	"log/slog"
	"net/http"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/cors"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"github.com/redis/go-redis/v9"

	// Handlers
	apimgmtHandler "github.com/leventkok/NavGo/internal/infrastructure/http/handler/apimanagement"
	auditHandler "github.com/leventkok/NavGo/internal/infrastructure/http/handler/audit"
	"github.com/leventkok/NavGo/internal/infrastructure/http/handler/health"
	iamHandler "github.com/leventkok/NavGo/internal/infrastructure/http/handler/iam"
	llmHandler "github.com/leventkok/NavGo/internal/infrastructure/http/handler/llm"
	realtimeHandler "github.com/leventkok/NavGo/internal/infrastructure/http/handler/realtime"
	securityHandler "github.com/leventkok/NavGo/internal/infrastructure/http/handler/security"
	tenantHandler "github.com/leventkok/NavGo/internal/infrastructure/http/handler/tenant"
	tripHandler "github.com/leventkok/NavGo/internal/infrastructure/http/handler/trip"

	// Services & middleware
	iamService "github.com/leventkok/NavGo/internal/domain/iam/service"
	"github.com/leventkok/NavGo/internal/gateway"
	"github.com/leventkok/NavGo/internal/shared/middleware"

	// Repositories (for tenant resolver middleware)
	tenantRepo "github.com/leventkok/NavGo/internal/domain/tenant/repository"
)

func maybeRequirePermission(rbac iamService.RBACService, permission string) func(http.Handler) http.Handler {
	if rbac == nil {
		return func(next http.Handler) http.Handler { return next }
	}
	return middleware.RequirePermission(rbac, permission)
}

// Dependencies holds all injected dependencies for the router.
type Dependencies struct {
	Logger *slog.Logger
	DB     *pgxpool.Pool
	Redis  *redis.Client

	CORSAllowedOrigins []string
	MaxBodyBytes       int64

	// Services
	AuthService iamService.AuthService
	RBACService iamService.RBACService

	// Handlers
	IAMHandler      *iamHandler.Handler
	TenantHandler   *tenantHandler.Handler
	APIMgmtHandler  *apimgmtHandler.Handler
	AuditHandler    *auditHandler.Handler
	RealtimeHandler *realtimeHandler.Handler
	TripHandler     *tripHandler.Handler
	LLMHandler      *llmHandler.Handler
	SecurityHandler *securityHandler.Handler
	AuditMiddleware func(http.Handler) http.Handler

	// Gateway
	GatewayPipeline *gateway.Pipeline

	// Repos needed for middleware
	OrgRepo       tenantRepo.OrgRepository
	WorkspaceRepo tenantRepo.WorkspaceRepository

	AuthRateLimiter middleware.RateLimiter
	LLMRateLimiter  middleware.RateLimiter
}

// New creates the root Chi router with all middleware and routes.
func New(deps Dependencies) *chi.Mux {
	r := chi.NewRouter()

	// Global middleware
	r.Use(middleware.RequestID)
	r.Use(middleware.Logging(deps.Logger))
	r.Use(middleware.Recoverer(deps.Logger))
	r.Use(middleware.SecurityHeaders)
	if deps.MaxBodyBytes > 0 {
		r.Use(middleware.MaxBodyBytes(deps.MaxBodyBytes))
	}
	r.Use(cors.Handler(middleware.CORSOptions(deps.CORSAllowedOrigins)))
	if deps.AuditMiddleware != nil {
		r.Use(deps.AuditMiddleware)
	}

	// Health endpoints
	healthHandler := health.NewHandler(deps.DB, deps.Redis)
	r.Get("/health/live", healthHandler.Liveness)
	r.Get("/health/ready", healthHandler.Readiness)

	// Prometheus metrics
	r.Handle("/metrics", promhttp.Handler())

	authLimiter := deps.AuthRateLimiter
	if authLimiter == nil {
		authLimiter = middleware.PreferRedisOrMemory(deps.Redis, "auth", 30, time.Minute)
	}
	llmLimiter := deps.LLMRateLimiter
	if llmLimiter == nil {
		llmLimiter = middleware.PreferRedisOrMemory(deps.Redis, "llm", 60, time.Minute)
	}

	// API v1 routes
	r.Route("/api/v1", func(r chi.Router) {
		// Public auth routes (no JWT required)
		r.Route("/auth", func(r chi.Router) {
			r.Group(func(r chi.Router) {
				r.Use(middleware.RateLimit(authLimiter, "auth"))
				if deps.SecurityHandler != nil {
					r.Post("/handshake", deps.SecurityHandler.Handshake)
					r.Post("/magic-link/request", deps.SecurityHandler.RequestMagicLink)
					r.Post("/magic-link/verify", deps.SecurityHandler.VerifyMagicLink)
				}
				if deps.IAMHandler != nil {
					r.Post("/register", deps.IAMHandler.Register)
					r.Post("/login", deps.IAMHandler.Login)
				}
			})
		})

		// Channel routes (single path pattern — chi forbids mounting /c/{channelId} twice)
		if deps.SecurityHandler != nil && deps.AuthService != nil {
			r.With(middleware.JWTAuth(deps.AuthService), middleware.VerifyChannelAccess).
				Get("/c/{channelId}/preflight", deps.SecurityHandler.ChannelPreflight)
		}

		// Protected routes (require JWT)
		r.Group(func(r chi.Router) {
			if deps.AuthService != nil {
				r.Use(middleware.JWTAuth(deps.AuthService))
				r.Use(middleware.RequireUserPrincipal)
			}

			// Tenant resolution middleware (with workspace support)
			if deps.OrgRepo != nil {
				r.Use(middleware.TenantResolverWithWorkspace(deps.OrgRepo, deps.WorkspaceRepo))
			}

			// Bind + channel me + scans
			if deps.SecurityHandler != nil {
				r.With(middleware.RateLimit(authLimiter, "bind")).Post("/auth/bind", deps.SecurityHandler.Bind)
				r.With(middleware.RequireBlended, middleware.VerifyChannelAccess).
					Get("/c/{channelId}/me", deps.SecurityHandler.ChannelMe)
				r.Route("/security/scans", func(r chi.Router) {
					r.Post("/", deps.SecurityHandler.IngestScan)
					r.Get("/", deps.SecurityHandler.ListScans)
				})
			}

			// WebSocket stays outside the gateway middleware group (chi forbids Use after routes).
			if deps.RealtimeHandler != nil {
				r.Get("/ws", deps.RealtimeHandler.Connect)
			}

			r.Group(func(r chi.Router) {
				// Gateway pipeline (rate limiting, permission enforcement for managed endpoints)
				if deps.GatewayPipeline != nil {
					r.Use(deps.GatewayPipeline.Enforce)
				}

				// User routes
				if deps.IAMHandler != nil {
					r.Get("/me", deps.IAMHandler.GetMe)
					r.With(maybeRequirePermission(deps.RBACService, "user:read")).Route("/users", func(r chi.Router) {
						r.Get("/", deps.IAMHandler.ListUsers)
						r.Get("/{id}", deps.IAMHandler.GetUser)
					})
					r.With(maybeRequirePermission(deps.RBACService, "user:write")).Post("/roles/assign", deps.IAMHandler.AssignRole)
				}

				// Organization routes
				if deps.TenantHandler != nil {
					r.Route("/organizations", func(r chi.Router) {
						r.With(maybeRequirePermission(deps.RBACService, "org:write")).Post("/", deps.TenantHandler.CreateOrg)
						r.With(maybeRequirePermission(deps.RBACService, "org:read")).Get("/", deps.TenantHandler.ListOrgs)
						r.Route("/{orgId}", func(r chi.Router) {
							r.With(maybeRequirePermission(deps.RBACService, "org:read")).Get("/", deps.TenantHandler.GetOrg)

							// Apps under organization
							r.Route("/apps", func(r chi.Router) {
								r.With(maybeRequirePermission(deps.RBACService, "app:write")).Post("/", deps.TenantHandler.CreateApp)
								r.With(maybeRequirePermission(deps.RBACService, "app:read")).Get("/", deps.TenantHandler.ListApps)
								r.Route("/{appId}", func(r chi.Router) {
									r.With(maybeRequirePermission(deps.RBACService, "app:read")).Get("/", deps.TenantHandler.GetApp)

									// API keys under app
									r.Route("/keys", func(r chi.Router) {
										r.With(maybeRequirePermission(deps.RBACService, "app:write")).Post("/", deps.TenantHandler.CreateAPIKey)
										r.With(maybeRequirePermission(deps.RBACService, "app:read")).Get("/", deps.TenantHandler.ListAPIKeys)
										r.With(maybeRequirePermission(deps.RBACService, "app:write")).Delete("/{keyId}", deps.TenantHandler.RevokeAPIKey)
									})

									// Endpoints under app
									if deps.APIMgmtHandler != nil {
										r.Route("/endpoints", func(r chi.Router) {
											r.With(maybeRequirePermission(deps.RBACService, "endpoint:write")).Post("/", deps.APIMgmtHandler.DefineEndpoint)
											r.With(maybeRequirePermission(deps.RBACService, "endpoint:read")).Get("/", deps.APIMgmtHandler.ListEndpoints)
											r.Route("/{endpointId}", func(r chi.Router) {
												r.With(maybeRequirePermission(deps.RBACService, "endpoint:read")).Get("/", deps.APIMgmtHandler.GetEndpoint)
												r.With(maybeRequirePermission(deps.RBACService, "endpoint:write")).Post("/retire", deps.APIMgmtHandler.RetireEndpoint)
												r.With(maybeRequirePermission(deps.RBACService, "endpoint:write")).Post("/activate", deps.APIMgmtHandler.ActivateEndpoint)
												r.With(maybeRequirePermission(deps.RBACService, "endpoint:write")).Put("/policy", deps.APIMgmtHandler.UpdatePolicy)
												r.With(maybeRequirePermission(deps.RBACService, "endpoint:read")).Get("/policy", deps.APIMgmtHandler.GetPolicy)
											})
										})
									}
								})
							})

							// Workspaces under organization
							r.Route("/workspaces", func(r chi.Router) {
								r.With(maybeRequirePermission(deps.RBACService, "org:write")).Post("/", deps.TenantHandler.CreateWorkspace)
								r.With(maybeRequirePermission(deps.RBACService, "org:read")).Get("/", deps.TenantHandler.ListWorkspaces)
								r.Route("/{workspaceId}", func(r chi.Router) {
									r.With(maybeRequirePermission(deps.RBACService, "org:write")).Put("/", deps.TenantHandler.UpdateWorkspace)
								})
							})

							// Audit logs under organization
							if deps.AuditHandler != nil {
								r.With(maybeRequirePermission(deps.RBACService, "org:read")).Get("/audit-logs", deps.AuditHandler.ListByOrg)
							}
						})
					})
				}

				// Audit logs by user
				if deps.AuditHandler != nil {
					r.With(maybeRequirePermission(deps.RBACService, "org:read")).Get("/users/{userId}/audit-logs", deps.AuditHandler.ListByUser)
				}

				// NavGo trip / places / routes (grounded itinerary) — blended JWT required for launch
				if deps.TripHandler != nil {
					r.Group(func(r chi.Router) {
						r.Use(middleware.RequireBlendedWhenEnabled)
						r.Post("/places/search", deps.TripHandler.SearchPlaces)
						r.Post("/routes/build", deps.TripHandler.BuildRoute)
						r.Post("/trips/plan", deps.TripHandler.PlanDay)
						r.Route("/itineraries", func(r chi.Router) {
							r.Post("/", deps.TripHandler.SaveItinerary)
							r.Get("/", deps.TripHandler.ListItineraries)
							r.Get("/{id}", deps.TripHandler.GetItinerary)
						})
					})
				}

				// LLM planning helpers
				if deps.LLMHandler != nil {
					r.Route("/llm", func(r chi.Router) {
						r.Use(middleware.RequireBlendedWhenEnabled)
						r.Use(middleware.LLMKillSwitch(deps.Redis))
						r.Use(middleware.RateLimit(llmLimiter, "llm"))
						r.Post("/parse-intent", deps.LLMHandler.ParseIntent)
						r.Post("/pick-stops", deps.LLMHandler.PickStops)
					})
				}

				// Catch-all handler for managed endpoints (must be last in the group)
				r.HandleFunc("/*", func(w http.ResponseWriter, r *http.Request) {
					w.Header().Set("Content-Type", "application/json")
					w.WriteHeader(http.StatusNotFound)
					_, _ = w.Write([]byte(`{"error":"endpoint not found","code":404,"message":"No endpoint registered for this path. Define the endpoint first using POST /api/v1/organizations/{orgId}/apps/{appId}/endpoints"}`))
				})
			}) // end gateway group
		})
	})

	r.NotFound(func(w http.ResponseWriter, r *http.Request) {
		if !strings.HasPrefix(r.URL.Path, "/api/v1") {
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusNotFound)
			_, _ = w.Write([]byte(`{"error":"not found","code":404}`))
			return
		}

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusNotFound)
		_, _ = w.Write([]byte(`{"error":"endpoint not found","code":404,"message":"No endpoint registered for this path. Define the endpoint first."}`))
	})

	return r
}
