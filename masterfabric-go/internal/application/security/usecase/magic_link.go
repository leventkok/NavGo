package usecase

import (
	"context"
	"log/slog"
	"os"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/leventkok/NavGo/internal/application/iam/dto"
	iamRepo "github.com/leventkok/NavGo/internal/domain/iam/repository"
	iamService "github.com/leventkok/NavGo/internal/domain/iam/service"
	secRepo "github.com/leventkok/NavGo/internal/domain/security/repository"
	domainErr "github.com/leventkok/NavGo/internal/shared/errors"
	sharedsec "github.com/leventkok/NavGo/internal/shared/security"
)

// MagicLinkRepository persists passwordless tokens.
type MagicLinkRepository interface {
	Create(ctx context.Context, email, tokenHash string, handshakeID uuid.UUID, expiresAt time.Time) (uuid.UUID, error)
	Consume(ctx context.Context, tokenHash string) (email string, handshakeID uuid.UUID, err error)
}

// RequestMagicLinkUseCase issues a one-time login token bound to a handshake.
type RequestMagicLinkUseCase struct {
	magic     MagicLinkRepository
	handshake secRepo.HandshakeRepository
}

func NewRequestMagicLinkUseCase(magic MagicLinkRepository, handshake secRepo.HandshakeRepository) *RequestMagicLinkUseCase {
	return &RequestMagicLinkUseCase{magic: magic, handshake: handshake}
}

type MagicLinkRequest struct {
	Email       string `json:"email" validate:"required,email"`
	HandshakeID string `json:"handshake_id" validate:"required,uuid"`
}

type MagicLinkRequestResponse struct {
	OK        bool   `json:"ok"`
	ExpiresIn int    `json:"expires_in_seconds"`
	DevToken  string `json:"dev_token,omitempty"`
}

func (uc *RequestMagicLinkUseCase) Execute(ctx context.Context, req MagicLinkRequest) (*MagicLinkRequestResponse, error) {
	if _, err := EnsureHandshakeValid(ctx, uc.handshake, req.HandshakeID); err != nil {
		return nil, err
	}
	hsID, _ := uuid.Parse(req.HandshakeID)
	plain, hash, err := sharedsec.NewOpaqueToken()
	if err != nil {
		return nil, domainErr.New(domainErr.ErrInternal, "token create failed", err)
	}
	exp := time.Now().UTC().Add(15 * time.Minute)
	if _, err := uc.magic.Create(ctx, strings.ToLower(strings.TrimSpace(req.Email)), hash, hsID, exp); err != nil {
		return nil, err
	}
	resp := &MagicLinkRequestResponse{OK: true, ExpiresIn: 900}
	if strings.ToLower(os.Getenv("APP_ENV")) != "production" && os.Getenv("SMTP_HOST") == "" {
		resp.DevToken = plain
		slog.Info("magic link token (dev/no-smtp)", "email", req.Email, "token", plain)
	}
	return resp, nil
}

// VerifyMagicLinkUseCase consumes a token and returns a user JWT (then client must bind).
type VerifyMagicLinkUseCase struct {
	magic    MagicLinkRepository
	userRepo iamRepo.UserRepository
	auth     iamService.AuthService
}

func NewVerifyMagicLinkUseCase(magic MagicLinkRepository, userRepo iamRepo.UserRepository, auth iamService.AuthService) *VerifyMagicLinkUseCase {
	return &VerifyMagicLinkUseCase{magic: magic, userRepo: userRepo, auth: auth}
}

type MagicLinkVerifyRequest struct {
	Token string `json:"token" validate:"required"`
}

func (uc *VerifyMagicLinkUseCase) Execute(ctx context.Context, req MagicLinkVerifyRequest) (*dto.LoginResponse, string, error) {
	email, handshakeID, err := uc.magic.Consume(ctx, sharedsec.HashOpaque(req.Token))
	if err != nil {
		return nil, "", err
	}
	user, err := uc.userRepo.GetByEmail(ctx, email)
	if err != nil {
		return nil, "", domainErr.New(domainErr.ErrUnauthorized, "unknown user for magic link", err)
	}
	if !user.IsActive() {
		return nil, "", domainErr.New(domainErr.ErrForbidden, "account is not active", nil)
	}
	token, err := uc.auth.GenerateToken(ctx, iamService.TokenClaims{
		UserID:    user.ID,
		Email:     user.Email,
		TokenKind: iamService.TokenKindUser,
	})
	if err != nil {
		return nil, "", domainErr.New(domainErr.ErrInternal, "failed to generate token", err)
	}
	return &dto.LoginResponse{
		Token: token,
		User: dto.UserInfo{
			ID: user.ID, Email: user.Email, FirstName: user.FirstName, LastName: user.LastName,
			Status: string(user.Status), CreatedAt: user.CreatedAt,
		},
	}, handshakeID.String(), nil
}
