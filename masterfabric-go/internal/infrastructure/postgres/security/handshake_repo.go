package security

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/leventkok/NavGo/internal/domain/security/model"
	domainErr "github.com/leventkok/NavGo/internal/shared/errors"
)

// HandshakeRepo implements HandshakeRepository.
type HandshakeRepo struct {
	db *pgxpool.Pool
}

// NewHandshakeRepo constructs a HandshakeRepo.
func NewHandshakeRepo(db *pgxpool.Pool) *HandshakeRepo {
	return &HandshakeRepo{db: db}
}

func (r *HandshakeRepo) Create(ctx context.Context, h *model.Handshake) error {
	_, err := r.db.Exec(ctx, `
		INSERT INTO auth_handshakes (id, device_id, channel_id, barrier_hash, barrier_hint, expires_at, created_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7)`,
		h.ID, h.DeviceID, h.ChannelID, h.BarrierHash, h.BarrierHint, h.ExpiresAt, h.CreatedAt,
	)
	if err != nil {
		return fmt.Errorf("insert handshake: %w", err)
	}
	return nil
}

func (r *HandshakeRepo) GetByID(ctx context.Context, id uuid.UUID) (*model.Handshake, error) {
	row := r.db.QueryRow(ctx, `
		SELECT id, device_id, channel_id, barrier_hash, barrier_hint, bound_user_id, expires_at, created_at, bound_at
		FROM auth_handshakes WHERE id = $1`, id)
	var h model.Handshake
	err := row.Scan(&h.ID, &h.DeviceID, &h.ChannelID, &h.BarrierHash, &h.BarrierHint, &h.BoundUserID, &h.ExpiresAt, &h.CreatedAt, &h.BoundAt)
	if err == pgx.ErrNoRows {
		return nil, domainErr.New(domainErr.ErrNotFound, "handshake not found", nil)
	}
	if err != nil {
		return nil, fmt.Errorf("get handshake: %w", err)
	}
	return &h, nil
}

func (r *HandshakeRepo) BindUser(ctx context.Context, id, userID uuid.UUID) error {
	tag, err := r.db.Exec(ctx, `
		UPDATE auth_handshakes SET bound_user_id = $2, bound_at = NOW()
		WHERE id = $1 AND bound_user_id IS NULL AND expires_at > NOW()`, id, userID)
	if err != nil {
		return fmt.Errorf("bind handshake: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return domainErr.New(domainErr.ErrUnauthorized, "handshake cannot be bound", nil)
	}
	return nil
}

// ScanRepo implements ScanRepository.
type ScanRepo struct {
	db *pgxpool.Pool
}

// NewScanRepo constructs a ScanRepo.
func NewScanRepo(db *pgxpool.Pool) *ScanRepo {
	return &ScanRepo{db: db}
}

func (r *ScanRepo) Create(ctx context.Context, s *model.SecurityScan) error {
	_, err := r.db.Exec(ctx, `
		INSERT INTO security_scans (id, organization_id, user_id, source, score_grade, score_value, report, created_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
		s.ID, s.OrganizationID, s.UserID, s.Source, s.ScoreGrade, s.ScoreValue, s.Report, s.CreatedAt,
	)
	if err != nil {
		return fmt.Errorf("insert security scan: %w", err)
	}
	return nil
}

func (r *ScanRepo) List(ctx context.Context, limit, offset int) ([]model.SecurityScan, error) {
	if limit <= 0 {
		limit = 20
	}
	rows, err := r.db.Query(ctx, `
		SELECT id, organization_id, user_id, source, score_grade, score_value, report, created_at
		FROM security_scans ORDER BY created_at DESC LIMIT $1 OFFSET $2`, limit, offset)
	if err != nil {
		return nil, fmt.Errorf("list security scans: %w", err)
	}
	defer rows.Close()
	var out []model.SecurityScan
	for rows.Next() {
		var s model.SecurityScan
		if err := rows.Scan(&s.ID, &s.OrganizationID, &s.UserID, &s.Source, &s.ScoreGrade, &s.ScoreValue, &s.Report, &s.CreatedAt); err != nil {
			return nil, fmt.Errorf("scan row: %w", err)
		}
		out = append(out, s)
	}
	return out, rows.Err()
}

// HashBarrier returns a hex SHA-256 of the barrier secret.
func HashBarrier(barrier string) string {
	sum := sha256.Sum256([]byte(barrier))
	return hex.EncodeToString(sum[:])
}

// NewBarrier generates a random barrier secret.
func NewBarrier() (string, error) {
	b := make([]byte, 32)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	return base64.RawURLEncoding.EncodeToString(b), nil
}

// HandshakeTTL is the pre-auth handshake lifetime.
const HandshakeTTL = 15 * time.Minute
