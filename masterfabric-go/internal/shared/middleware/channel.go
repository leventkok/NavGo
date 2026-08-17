package middleware

import (
	"context"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/leventkok/NavGo/internal/domain/iam/service"
	"github.com/leventkok/NavGo/internal/shared/response"
	sharedsec "github.com/leventkok/NavGo/internal/shared/security"
)

const (
	ContextKeyTokenKind   contextKey = "auth_token_kind"
	ContextKeyDeviceID    contextKey = "auth_device_id"
	ContextKeyChannelID   contextKey = "auth_channel_id"
	ContextKeyHandshakeID contextKey = "auth_handshake_id"
)

// InjectTokenMeta stores handshake-related claims on the context after JWTAuth.
func InjectTokenMeta(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		claims, ok := r.Context().Value(ContextKeyClaims).(*service.TokenClaims)
		if ok && claims != nil {
			ctx := r.Context()
			ctx = context.WithValue(ctx, ContextKeyTokenKind, claims.TokenKind)
			ctx = context.WithValue(ctx, ContextKeyDeviceID, claims.DeviceID)
			ctx = context.WithValue(ctx, ContextKeyChannelID, claims.ChannelID)
			ctx = context.WithValue(ctx, ContextKeyHandshakeID, claims.HandshakeID)
			r = r.WithContext(ctx)
		}
		next.ServeHTTP(w, r)
	})
}

// RequireBlended rejects non-blended tokens (channel-bound / sensitive APIs).
func RequireBlended(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		kind, _ := r.Context().Value(ContextKeyTokenKind).(string)
		if kind != service.TokenKindBlended {
			response.JSON(w, http.StatusForbidden, map[string]string{"error": "blended token required; call /api/v1/auth/bind"})
			return
		}
		next.ServeHTTP(w, r)
	})
}

// RequireBlendedWhenEnabled enforces blended tokens when REQUIRE_BLENDED_SENSITIVE=true (default).
func RequireBlendedWhenEnabled(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if sharedsec.RequireBlendedSensitive() {
			RequireBlended(next).ServeHTTP(w, r)
			return
		}
		next.ServeHTTP(w, r)
	})
}

// VerifyChannelAccess ensures the path channel matches the JWT channel claim.
func VerifyChannelAccess(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		pathChannel := chi.URLParam(r, "channelId")
		channelID, _ := r.Context().Value(ContextKeyChannelID).(uuid.UUID)
		if pathChannel == "" || channelID == uuid.Nil || pathChannel != channelID.String() {
			response.JSON(w, http.StatusForbidden, map[string]string{"error": "channel access denied"})
			return
		}
		next.ServeHTTP(w, r)
	})
}

// RequireUserPrincipal rejects device-only tokens on user APIs.
func RequireUserPrincipal(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		kind, _ := r.Context().Value(ContextKeyTokenKind).(string)
		if kind == service.TokenKindDevice {
			response.JSON(w, http.StatusForbidden, map[string]string{"error": "device token cannot access this resource"})
			return
		}
		userID, ok := UserIDFromContext(r.Context())
		if !ok || userID == uuid.Nil {
			response.JSON(w, http.StatusUnauthorized, map[string]string{"error": "user principal required"})
			return
		}
		next.ServeHTTP(w, r)
	})
}

// ChannelIDFromContext extracts channel id from context.
func ChannelIDFromContext(ctx context.Context) (uuid.UUID, bool) {
	id, ok := ctx.Value(ContextKeyChannelID).(uuid.UUID)
	return id, ok && id != uuid.Nil
}
