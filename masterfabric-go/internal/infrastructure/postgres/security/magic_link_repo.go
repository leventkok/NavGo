package security

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	domainErr "github.com/leventkok/NavGo/internal/shared/errors"
)

// MagicLinkRepo persists magic-link tokens.
type MagicLinkRepo struct {
	db *pgxpool.Pool
}

func NewMagicLinkRepo(db *pgxpool.Pool) *MagicLinkRepo {
	return &MagicLinkRepo{db: db}
}

func (r *MagicLinkRepo) Create(ctx context.Context, email, tokenHash string, handshakeID uuid.UUID, expiresAt time.Time) (uuid.UUID, error) {
	id := uuid.New()
	_, err := r.db.Exec(ctx, `
		INSERT INTO auth_magic_links (id, email, token_hash, handshake_id, expires_at, created_at)
		VALUES ($1, $2, $3, $4, $5, NOW())`, id, email, tokenHash, handshakeID, expiresAt)
	if err != nil {
		return uuid.Nil, fmt.Errorf("insert magic link: %w", err)
	}
	return id, nil
}

func (r *MagicLinkRepo) Consume(ctx context.Context, tokenHash string) (string, uuid.UUID, error) {
	tx, err := r.db.Begin(ctx)
	if err != nil {
		return "", uuid.Nil, err
	}
	defer func() { _ = tx.Rollback(ctx) }()

	var email string
	var handshakeID uuid.UUID
	var usedAt *time.Time
	var expiresAt time.Time
	err = tx.QueryRow(ctx, `
		SELECT email, handshake_id, used_at, expires_at FROM auth_magic_links
		WHERE token_hash = $1 FOR UPDATE`, tokenHash).Scan(&email, &handshakeID, &usedAt, &expiresAt)
	if err == pgx.ErrNoRows {
		return "", uuid.Nil, domainErr.New(domainErr.ErrUnauthorized, "invalid magic link", nil)
	}
	if err != nil {
		return "", uuid.Nil, fmt.Errorf("get magic link: %w", err)
	}
	if usedAt != nil {
		return "", uuid.Nil, domainErr.New(domainErr.ErrUnauthorized, "magic link already used", nil)
	}
	if time.Now().UTC().After(expiresAt) {
		return "", uuid.Nil, domainErr.New(domainErr.ErrUnauthorized, "magic link expired", nil)
	}
	if _, err := tx.Exec(ctx, `UPDATE auth_magic_links SET used_at = NOW() WHERE token_hash = $1`, tokenHash); err != nil {
		return "", uuid.Nil, err
	}
	if err := tx.Commit(ctx); err != nil {
		return "", uuid.Nil, err
	}
	return email, handshakeID, nil
}
