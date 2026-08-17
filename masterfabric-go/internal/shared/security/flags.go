package security

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"os"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/leventkok/NavGo/internal/domain/audit/model"
	"github.com/leventkok/NavGo/internal/domain/audit/repository"
)

// Flags are production defaults for a near-term launch.
func RequireAuthHandshake() bool {
	return envBool("REQUIRE_AUTH_HANDSHAKE", true)
}

func RequireBlendedSensitive() bool {
	return envBool("REQUIRE_BLENDED_SENSITIVE", true)
}

func LLMKillSwitchEnv() bool {
	return envBool("LLM_KILL_SWITCH", false)
}

func envBool(key string, def bool) bool {
	v := strings.TrimSpace(strings.ToLower(os.Getenv(key)))
	if v == "" {
		return def
	}
	return v == "1" || v == "true" || v == "yes" || v == "on"
}

// AuditWriter writes typed security/audit events.
type AuditWriter struct {
	repo repository.AuditRepository
}

func NewAuditWriter(repo repository.AuditRepository) *AuditWriter {
	return &AuditWriter{repo: repo}
}

func (w *AuditWriter) Write(ctx context.Context, action, resourceType, resourceID string, orgID uuid.UUID, userID *uuid.UUID, meta []byte) {
	if w == nil || w.repo == nil {
		return
	}
	if orgID == uuid.Nil {
		// Use nil org sentinel-free skip — table requires org; use zero UUID only if we have a system org.
		// Skip when unknown to avoid NOT NULL violations.
		return
	}
	entry := &model.AuditLog{
		OrganizationID: orgID,
		UserID:         userID,
		Action:         action,
		ResourceType:   resourceType,
		ResourceID:     resourceID,
		Metadata:       meta,
		CreatedAt:      time.Now().UTC(),
	}
	_ = w.repo.Create(ctx, entry)
}

// NewOpaqueToken returns a random URL-safe token and its sha256 hex hash.
func NewOpaqueToken() (plain, hash string, err error) {
	b := make([]byte, 32)
	if _, err = rand.Read(b); err != nil {
		return "", "", err
	}
	plain = hex.EncodeToString(b)
	sum := sha256.Sum256([]byte(plain))
	hash = hex.EncodeToString(sum[:])
	return plain, hash, nil
}

func HashOpaque(plain string) string {
	sum := sha256.Sum256([]byte(plain))
	return hex.EncodeToString(sum[:])
}

func FormatChannelPath(channelID uuid.UUID) string {
	return fmt.Sprintf("/api/v1/c/%s", channelID.String())
}
