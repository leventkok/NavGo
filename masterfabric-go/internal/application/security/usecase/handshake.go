package usecase

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/leventkok/NavGo/internal/application/security/dto"
	iamService "github.com/leventkok/NavGo/internal/domain/iam/service"
	"github.com/leventkok/NavGo/internal/domain/security/model"
	"github.com/leventkok/NavGo/internal/domain/security/repository"
	pgsec "github.com/leventkok/NavGo/internal/infrastructure/postgres/security"
	domainErr "github.com/leventkok/NavGo/internal/shared/errors"
)

// HandshakeUseCase creates pre-auth device barriers.
type HandshakeUseCase struct {
	repo repository.HandshakeRepository
	auth iamService.AuthService
}

// NewHandshakeUseCase constructs HandshakeUseCase.
func NewHandshakeUseCase(repo repository.HandshakeRepository, auth iamService.AuthService) *HandshakeUseCase {
	return &HandshakeUseCase{repo: repo, auth: auth}
}

// Execute creates a handshake and device JWT.
func (uc *HandshakeUseCase) Execute(ctx context.Context, _ dto.HandshakeRequest) (*dto.HandshakeResponse, error) {
	barrier, err := pgsec.NewBarrier()
	if err != nil {
		return nil, domainErr.New(domainErr.ErrInternal, "failed to create barrier", err)
	}
	now := time.Now().UTC()
	h := &model.Handshake{
		ID:          uuid.New(),
		DeviceID:    uuid.New(),
		ChannelID:   uuid.New(),
		BarrierHash: pgsec.HashBarrier(barrier),
		BarrierHint: barrier[:min(8, len(barrier))],
		ExpiresAt:   now.Add(pgsec.HandshakeTTL),
		CreatedAt:   now,
	}
	if err := uc.repo.Create(ctx, h); err != nil {
		return nil, err
	}

	token, err := uc.auth.GenerateToken(ctx, iamService.TokenClaims{
		TokenKind:   iamService.TokenKindDevice,
		DeviceID:    h.DeviceID,
		HandshakeID: h.ID,
		ChannelID:   h.ChannelID,
		BarrierFP:   h.BarrierHash,
	})
	if err != nil {
		return nil, domainErr.New(domainErr.ErrInternal, "failed to issue device token", err)
	}

	return &dto.HandshakeResponse{
		HandshakeID: h.ID.String(),
		DeviceID:    h.DeviceID.String(),
		ChannelID:   h.ChannelID.String(),
		ChannelPath: fmt.Sprintf("/api/v1/c/%s", h.ChannelID.String()),
		DeviceToken: token,
		Barrier:     barrier,
		ExpiresAt:   h.ExpiresAt,
	}, nil
}

// BindUseCase blends an authenticated user with a handshake device.
type BindUseCase struct {
	repo repository.HandshakeRepository
	auth iamService.AuthService
}

// NewBindUseCase constructs BindUseCase.
func NewBindUseCase(repo repository.HandshakeRepository, auth iamService.AuthService) *BindUseCase {
	return &BindUseCase{repo: repo, auth: auth}
}

// Execute verifies barrier and issues a blended JWT.
func (uc *BindUseCase) Execute(ctx context.Context, userID uuid.UUID, email string, orgID uuid.UUID, req dto.BindRequest) (*dto.BindResponse, error) {
	hsID, err := uuid.Parse(req.HandshakeID)
	if err != nil {
		return nil, domainErr.New(domainErr.ErrBadRequest, "invalid handshake_id", err)
	}
	h, err := uc.repo.GetByID(ctx, hsID)
	if err != nil {
		return nil, err
	}
	if time.Now().UTC().After(h.ExpiresAt) {
		return nil, domainErr.New(domainErr.ErrUnauthorized, "handshake expired", nil)
	}
	if pgsec.HashBarrier(req.Barrier) != h.BarrierHash {
		return nil, domainErr.New(domainErr.ErrUnauthorized, "invalid barrier", nil)
	}
	if err := uc.repo.BindUser(ctx, h.ID, userID); err != nil {
		return nil, err
	}

	exp := time.Now().UTC().Add(8 * time.Hour)
	token, err := uc.auth.GenerateToken(ctx, iamService.TokenClaims{
		UserID:         userID,
		Email:          email,
		OrganizationID: orgID,
		TokenKind:      iamService.TokenKindBlended,
		DeviceID:       h.DeviceID,
		HandshakeID:    h.ID,
		ChannelID:      h.ChannelID,
		BarrierFP:      h.BarrierHash,
	})
	if err != nil {
		return nil, domainErr.New(domainErr.ErrInternal, "failed to issue blended token", err)
	}

	return &dto.BindResponse{
		Token:       token,
		TokenKind:   iamService.TokenKindBlended,
		ChannelID:   h.ChannelID.String(),
		ChannelPath: fmt.Sprintf("/api/v1/c/%s", h.ChannelID.String()),
		ExpiresAt:   exp,
	}, nil
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}
