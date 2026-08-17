package repository

import (
	"context"

	"github.com/google/uuid"
	"github.com/leventkok/NavGo/internal/domain/security/model"
)

// HandshakeRepository persists auth handshakes.
type HandshakeRepository interface {
	Create(ctx context.Context, h *model.Handshake) error
	GetByID(ctx context.Context, id uuid.UUID) (*model.Handshake, error)
	BindUser(ctx context.Context, id, userID uuid.UUID) error
}

// ScanRepository persists security scan reports.
type ScanRepository interface {
	Create(ctx context.Context, s *model.SecurityScan) error
	List(ctx context.Context, limit, offset int) ([]model.SecurityScan, error)
}
