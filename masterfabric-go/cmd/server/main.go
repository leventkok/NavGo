package main

import (
	"context"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/redis/go-redis/v9"

	// Infrastructure
	infraAuth "github.com/leventkok/NavGo/internal/infrastructure/auth"
	apimgmtHandler "github.com/leventkok/NavGo/internal/infrastructure/http/handler/apimanagement"
	auditHandler "github.com/leventkok/NavGo/internal/infrastructure/http/handler/audit"
	iamHandler "github.com/leventkok/NavGo/internal/infrastructure/http/handler/iam"
	llmHandler "github.com/leventkok/NavGo/internal/infrastructure/http/handler/llm"
	realtimeHandler "github.com/leventkok/NavGo/internal/infrastructure/http/handler/realtime"
	tenantHandler "github.com/leventkok/NavGo/internal/infrastructure/http/handler/tenant"
	tripHandler "github.com/leventkok/NavGo/internal/infrastructure/http/handler/trip"
	"github.com/leventkok/NavGo/internal/infrastructure/http/router"
	infraKafka "github.com/leventkok/NavGo/internal/infrastructure/kafka"
	llminfra "github.com/leventkok/NavGo/internal/infrastructure/llm"
	placesinfra "github.com/leventkok/NavGo/internal/infrastructure/places"
	pgApimgmt "github.com/leventkok/NavGo/internal/infrastructure/postgres/apimanagement"
	pgAudit "github.com/leventkok/NavGo/internal/infrastructure/postgres/audit"
	pgIam "github.com/leventkok/NavGo/internal/infrastructure/postgres/iam"
	placespg "github.com/leventkok/NavGo/internal/infrastructure/postgres/places"
	pgTenant "github.com/leventkok/NavGo/internal/infrastructure/postgres/tenant"
	trippg "github.com/leventkok/NavGo/internal/infrastructure/postgres/trip"
	infraWS "github.com/leventkok/NavGo/internal/infrastructure/websocket"

	// Application use cases
	apimgmtUC "github.com/leventkok/NavGo/internal/application/apimanagement/usecase"
	iamUC "github.com/leventkok/NavGo/internal/application/iam/usecase"
	llmUC "github.com/leventkok/NavGo/internal/application/llm/usecase"
	realtimeUC "github.com/leventkok/NavGo/internal/application/realtime/usecase"
	tenantUC "github.com/leventkok/NavGo/internal/application/tenant/usecase"
	tripUC "github.com/leventkok/NavGo/internal/application/trip/usecase"

	// Gateway
	"github.com/leventkok/NavGo/internal/gateway"
	gatewayInterceptors "github.com/leventkok/NavGo/internal/infrastructure/gateway/interceptors"

	// Shared
	"github.com/leventkok/NavGo/internal/shared/cache"
	"github.com/leventkok/NavGo/internal/shared/config"
	"github.com/leventkok/NavGo/internal/shared/database"
	"github.com/leventkok/NavGo/internal/shared/events"
	"github.com/leventkok/NavGo/internal/shared/logger"
	"github.com/leventkok/NavGo/internal/shared/telemetry"
	"github.com/leventkok/NavGo/internal/shared/version"
)

func main() {
	if err := run(); err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}
}

func run() error {
	// Load configuration
	cfg := config.Load()

	// Initialize logger
	log := logger.New(cfg.Log.Level, cfg.Log.Format)
	slog.SetDefault(log)

	log.Info("starting navgo",
		"host", cfg.Server.Host,
		"port", cfg.Server.Port,
	)

	if cfg.JWT.Secret == "change-me-in-production" {
		log.Warn("JWT_SECRET is unset; authentication uses a known default value")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Initialize OpenTelemetry
	otelShutdown, err := telemetry.Setup(ctx, version.ServiceName, version.Version)
	if err != nil {
		log.Warn("opentelemetry setup failed", "error", err)
	} else {
		defer func() { _ = otelShutdown(context.Background()) }()
		log.Info("opentelemetry initialized")
	}

	// Initialize PostgreSQL
	db, err := database.NewPostgresPool(ctx, cfg.Database)
	if err != nil {
		log.Warn("postgres unavailable, running without database", "error", err)
		db = nil
	} else {
		defer db.Close()
		log.Info("connected to postgres")
	}

	// Initialize Redis
	redisClient, err := cache.NewRedisClient(ctx, cfg.Redis)
	if err != nil {
		log.Warn("redis unavailable, running without cache", "error", err)
		redisClient = nil
	} else {
		defer redisClient.Close()
		log.Info("connected to redis")
	}

	// Initialize event bus (Kafka or in-process)
	eventBus := initEventBus(ctx, cfg, log)
	defer func() { _ = eventBus.Close() }()

	// Build dependencies
	deps := buildDependencies(log, cfg, db, redisClient, eventBus)

	// Build router
	r := router.New(deps)

	// Create HTTP server
	addr := fmt.Sprintf("%s:%d", cfg.Server.Host, cfg.Server.Port)
	srv := &http.Server{
		Addr:         addr,
		Handler:      r,
		ReadTimeout:  cfg.Server.ReadTimeout,
		WriteTimeout: cfg.Server.WriteTimeout,
		IdleTimeout:  cfg.Server.IdleTimeout,
	}

	// Graceful shutdown
	shutdown := make(chan os.Signal, 1)
	signal.Notify(shutdown, os.Interrupt, syscall.SIGTERM)

	serverErr := make(chan error, 1)
	go func() {
		log.Info("listening", "addr", addr)
		serverErr <- srv.ListenAndServe()
	}()

	select {
	case err := <-serverErr:
		if err != nil && err != http.ErrServerClosed {
			return fmt.Errorf("server error: %w", err)
		}
	case sig := <-shutdown:
		log.Info("shutdown signal received", "signal", sig)
		shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer shutdownCancel()

		if err := srv.Shutdown(shutdownCtx); err != nil {
			_ = srv.Close()
			return fmt.Errorf("graceful shutdown failed: %w", err)
		}
		log.Info("server stopped gracefully")
	}

	return nil
}

// initEventBus creates either a Kafka bus or an in-process bus based on config.
func initEventBus(ctx context.Context, cfg *config.Config, log *slog.Logger) events.EventBus {
	if !cfg.Kafka.Enabled {
		log.Info("using in-process event bus (set KAFKA_ENABLED=true to use Kafka)")
		return events.NewInProcessBus(log, 256)
	}

	log.Info("initializing kafka event bus",
		"brokers", cfg.Kafka.Brokers,
		"group_id", cfg.Kafka.GroupID,
	)

	// Ensure topics exist
	if len(cfg.Kafka.Brokers) > 0 {
		if err := infraKafka.EnsureTopics(
			ctx,
			cfg.Kafka.Brokers[0],
			infraKafka.DefaultTopics(),
			cfg.Kafka.NumPartitions,
			cfg.Kafka.ReplicationFactor,
			log,
		); err != nil {
			log.Warn("failed to ensure kafka topics, falling back to in-process bus", "error", err)
			return events.NewInProcessBus(log, 256)
		}
	}

	kafkaBus := infraKafka.NewBus(cfg.Kafka.Brokers, cfg.Kafka.GroupID, log)

	// Start consuming (after subscriptions are registered in buildDependencies)
	// We start consumption with a background context so it outlives the startup ctx.
	kafkaBus.Start(context.Background())

	log.Info("kafka event bus initialized")
	return kafkaBus
}

func buildDependencies(
	log *slog.Logger,
	cfg *config.Config,
	db *pgxpool.Pool,
	redisClient *redis.Client,
	eventBus events.EventBus,
) router.Dependencies {
	deps := router.Dependencies{
		Logger:             log,
		DB:                 db,
		Redis:              redisClient,
		CORSAllowedOrigins: cfg.Server.CORSAllowedOrigins,
		MaxBodyBytes:       cfg.Server.MaxBodyBytes,
	}

	if db == nil {
		log.Warn("database not available, API endpoints will not work")
		return deps
	}

	// --- Repositories ---
	userRepo := pgIam.NewUserRepo(db)
	roleRepo := pgIam.NewRoleRepo(db)
	orgRepo := pgTenant.NewOrgRepo(db)
	workspaceRepo := pgTenant.NewWorkspaceRepository(db)
	appRepo := pgTenant.NewAppRepo(db)
	apiKeyRepo := pgTenant.NewAPIKeyRepo(db)
	endpointRepo := pgApimgmt.NewEndpointRepo(db)
	policyRepo := pgApimgmt.NewPolicyRepo(db)
	auditRepo := pgAudit.NewAuditRepo(db)

	// --- Services ---
	jwtService := infraAuth.NewJWTService(cfg.JWT)
	rbacService := infraAuth.NewRBACService(roleRepo, redisClient)

	deps.AuthService = jwtService
	deps.RBACService = rbacService
	deps.OrgRepo = orgRepo
	deps.WorkspaceRepo = workspaceRepo

	// --- Use cases (with event bus for domain event publishing) ---
	registerUC := iamUC.NewRegisterUseCase(userRepo, jwtService, eventBus)
	loginUC := iamUC.NewLoginUseCase(userRepo, jwtService)
	assignRoleUC := iamUC.NewAssignRoleUseCase(roleRepo, rbacService, eventBus)
	createOrgUC := tenantUC.NewCreateOrgUseCase(orgRepo, eventBus)
	createWorkspaceUC := tenantUC.NewCreateWorkspaceUseCase(workspaceRepo, orgRepo, eventBus)
	listWorkspacesUC := tenantUC.NewListWorkspacesUseCase(workspaceRepo)
	updateWorkspaceUC := tenantUC.NewUpdateWorkspaceUseCase(workspaceRepo)
	createAppUC := tenantUC.NewCreateAppUseCase(appRepo, orgRepo, eventBus)
	manageKeysUC := tenantUC.NewManageAPIKeysUseCase(apiKeyRepo)
	defineEndpointUC := apimgmtUC.NewDefineEndpointUseCase(endpointRepo, eventBus)
	updatePolicyUC := apimgmtUC.NewUpdatePolicyUseCase(policyRepo)
	retireEndpointUC := apimgmtUC.NewRetireEndpointUseCase(endpointRepo, eventBus)
	activateEndpointUC := apimgmtUC.NewActivateEndpointUseCase(endpointRepo, eventBus)

	// --- Register sample Kafka consumers ---
	// Log all IAM events
	eventBus.Subscribe(events.TopicIAM, func(ctx context.Context, event events.Event) error {
		log.Info("iam event received", "event", event)
		return nil
	})
	// Log all tenant events
	eventBus.Subscribe(events.TopicTenant, func(ctx context.Context, event events.Event) error {
		log.Info("tenant event received", "event", event)
		return nil
	})
	// Log all API management events
	eventBus.Subscribe(events.TopicAPIManagement, func(ctx context.Context, event events.Event) error {
		log.Info("api-management event received", "event", event)
		return nil
	})

	// --- Handlers ---
	deps.IAMHandler = iamHandler.NewHandler(registerUC, loginUC, assignRoleUC, userRepo)
	deps.TenantHandler = tenantHandler.NewHandler(
		createOrgUC,
		createAppUC,
		manageKeysUC,
		createWorkspaceUC,
		listWorkspacesUC,
		updateWorkspaceUC,
		orgRepo,
		appRepo,
	)
	deps.APIMgmtHandler = apimgmtHandler.NewHandler(defineEndpointUC, updatePolicyUC, retireEndpointUC, activateEndpointUC, endpointRepo, policyRepo)
	deps.AuditHandler = auditHandler.NewHandler(auditRepo)

	// --- NavGo trip / places (Google-shaped ports; mock until GOOGLE_MAPS_API_KEY) ---
	placeCache := placespg.NewCacheRepo(db)
	placesClient, directionsClient := placesinfra.NewClients(cfg.GoogleMaps.APIKey, placeCache)
	itineraryRepo := trippg.NewItineraryRepo(db)
	tripService := tripUC.NewService(placesClient, directionsClient, placeCache, itineraryRepo)
	deps.TripHandler = tripHandler.NewHandler(tripService)
	if cfg.GoogleMaps.APIKey == "" {
		log.Info("GOOGLE_MAPS_API_KEY unset; using mock Places/Directions adapters")
	} else {
		log.Info("GOOGLE_MAPS_API_KEY set; using Google Places (New) + Routes adapters")
	}

	// --- Optional LLM (Ollama / OpenAI-compatible) ---
	if cfg.LLM.Enabled() {
		llmClient := llminfra.NewOpenAIClient(cfg.LLM.BaseURL, cfg.LLM.Model, cfg.LLM.APIKey)
		llmService := llmUC.NewService(llmClient, cfg.LLM.Model)
		deps.LLMHandler = llmHandler.NewHandler(llmService)
		log.Info("LLM enabled", "base_url", cfg.LLM.BaseURL, "model", cfg.LLM.Model)
	} else {
		log.Info("LLM_BASE_URL unset; /api/v1/llm/* disabled")
	}

	// --- WebSocket real-time hub ---
	wsHub := infraWS.NewHub(log, cfg.WebSocket.MaxConnections)
	eventBridge := infraWS.NewEventBridge(wsHub, appRepo, log)
	eventBridge.Register(eventBus)

	validateConnectUC := realtimeUC.NewValidateConnectUseCase(appRepo, rbacService)
	wsUpgrader := infraWS.NewUpgrader(infraWS.UpgraderConfig{
		ReadBufferSize:  cfg.WebSocket.ReadBufferSize,
		WriteBufferSize: cfg.WebSocket.WriteBufferSize,
		AllowedOrigins:  cfg.Server.CORSAllowedOrigins,
	})
	deps.RealtimeHandler = realtimeHandler.NewHandler(realtimeHandler.Config{
		ValidateUC:   validateConnectUC,
		AuthService:  jwtService,
		Hub:          wsHub,
		Upgrader:     wsUpgrader,
		PingInterval: cfg.WebSocket.PingIntervalSec,
		Logger:       log,
		Enabled:      cfg.WebSocket.Enabled,
	})

	// --- Gateway pipeline with interceptors ---
	// Create interceptor chain: schema validation, PII masking, request/response transformers
	piiMasker := gatewayInterceptors.NewPIIMasker(
		[]string{"password", "password_hash", "api_key", "secret", "token", "ssn", "credit_card"},
		"***",
	)
	schemaValidator := gatewayInterceptors.NewSchemaValidator()

	// Create dynamic handler resolver for routing requests to backend service handlers
	// This supports:
	// 1. Registered handlers (if you register specific handlers)
	// 2. HTTP proxy to external services (if backend_service is a URL or configured)
	// 3. Generic dynamic database handler (automatically performs CRUD operations)
	backendRegistry := gateway.NewBackendRegistry()
	dynamicResolver := gateway.NewDynamicHandlerResolver(backendRegistry, log, db)

	// Optional: Register service configurations for HTTP proxying
	// Example:
	// dynamicResolver.RegisterServiceConfig("product-service", gateway.ServiceConfig{
	//     BaseURL: "https://api.example.com/products",
	//     Headers: map[string]string{"Authorization": "Bearer token"},
	// })

	// Optional: Register specific handlers for services that need custom logic
	// Example:
	// productHandler := handlers.NewProductHandler(...)
	// backendRegistry.Register("product-service", productHandler)

	// Wire interceptors into gateway pipeline with dynamic resolver
	deps.GatewayPipeline = gateway.NewPipeline(
		endpointRepo,
		policyRepo,
		rbacService,
		redisClient,
		log,
		dynamicResolver, // Dynamic handler resolver (supports registered handlers, HTTP proxy, and generic handling)
		schemaValidator, // Schema validation interceptor
		piiMasker,       // PII masking interceptor
	)

	return deps
}
