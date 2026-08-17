package usecase

import (
	"context"
	"time"

	"github.com/google/uuid"
	secModel "github.com/leventkok/NavGo/internal/domain/security/model"
	secRepo "github.com/leventkok/NavGo/internal/domain/security/repository"
	domainErr "github.com/leventkok/NavGo/internal/shared/errors"
	sharedsec "github.com/leventkok/NavGo/internal/shared/security"
)

// EnsureHandshakeValid checks handshake exists and is unexpired when provided/required.
func EnsureHandshakeValid(ctx context.Context, repo secRepo.HandshakeRepository, handshakeID string) (*secModel.Handshake, error) {
	if handshakeID == "" {
		if sharedsec.RequireAuthHandshake() {
			return nil, domainErr.New(domainErr.ErrBadRequest, "handshake_id is required", nil)
		}
		return nil, nil
	}
	id, err := uuid.Parse(handshakeID)
	if err != nil {
		return nil, domainErr.New(domainErr.ErrBadRequest, "invalid handshake_id", err)
	}
	h, err := repo.GetByID(ctx, id)
	if err != nil {
		return nil, err
	}
	if time.Now().UTC().After(h.ExpiresAt) {
		return nil, domainErr.New(domainErr.ErrUnauthorized, "handshake expired", nil)
	}
	return h, nil
}
