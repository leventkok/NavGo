package auth

import (
	"context"
	"fmt"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"github.com/leventkok/NavGo/internal/domain/iam/service"
	"github.com/leventkok/NavGo/internal/shared/config"
	domainErr "github.com/leventkok/NavGo/internal/shared/errors"
	"golang.org/x/crypto/bcrypt"
)

// JWTService implements service.AuthService using JWT and bcrypt.
type JWTService struct {
	secret     []byte
	expiration time.Duration
	issuer     string
}

// NewJWTService creates a new JWTService from config.
func NewJWTService(cfg config.JWTConfig) *JWTService {
	return &JWTService{
		secret:     []byte(cfg.Secret),
		expiration: time.Duration(cfg.ExpirationHours) * time.Hour,
		issuer:     cfg.Issuer,
	}
}

// customClaims extends JWT standard claims with our domain data.
type customClaims struct {
	jwt.RegisteredClaims
	UserID         string   `json:"user_id,omitempty"`
	Email          string   `json:"email,omitempty"`
	OrganizationID string   `json:"organization_id,omitempty"`
	Roles          []string `json:"roles,omitempty"`
	Permissions    []string `json:"permissions,omitempty"`
	TokenKind      string   `json:"token_kind,omitempty"`
	DeviceID       string   `json:"device_id,omitempty"`
	HandshakeID    string   `json:"handshake_id,omitempty"`
	ChannelID      string   `json:"channel_id,omitempty"`
	BarrierFP      string   `json:"barrier_fp,omitempty"`
}

func (s *JWTService) HashPassword(password string) (string, error) {
	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return "", fmt.Errorf("hash password: %w", err)
	}
	return string(hash), nil
}

func (s *JWTService) VerifyPassword(hashedPassword, password string) error {
	if err := bcrypt.CompareHashAndPassword([]byte(hashedPassword), []byte(password)); err != nil {
		return domainErr.New(domainErr.ErrUnauthorized, "invalid credentials", nil)
	}
	return nil
}

func (s *JWTService) GenerateToken(_ context.Context, claims service.TokenClaims) (string, error) {
	now := time.Now().UTC()
	kind := claims.TokenKind
	if kind == "" {
		kind = service.TokenKindUser
	}

	ttl := s.expiration
	switch kind {
	case service.TokenKindDevice:
		ttl = 15 * time.Minute
	case service.TokenKindBlended:
		ttl = 8 * time.Hour
	}

	subject := claims.UserID.String()
	if claims.UserID == uuid.Nil && claims.DeviceID != uuid.Nil {
		subject = claims.DeviceID.String()
	}

	c := customClaims{
		RegisteredClaims: jwt.RegisteredClaims{
			Issuer:    s.issuer,
			Subject:   subject,
			ExpiresAt: jwt.NewNumericDate(now.Add(ttl)),
			IssuedAt:  jwt.NewNumericDate(now),
			ID:        uuid.New().String(),
		},
		Email:     claims.Email,
		Roles:     claims.Roles,
		Permissions: claims.Permissions,
		TokenKind: kind,
		BarrierFP: claims.BarrierFP,
	}
	if claims.UserID != uuid.Nil {
		c.UserID = claims.UserID.String()
	}
	if claims.OrganizationID != uuid.Nil {
		c.OrganizationID = claims.OrganizationID.String()
	}
	if claims.DeviceID != uuid.Nil {
		c.DeviceID = claims.DeviceID.String()
	}
	if claims.HandshakeID != uuid.Nil {
		c.HandshakeID = claims.HandshakeID.String()
	}
	if claims.ChannelID != uuid.Nil {
		c.ChannelID = claims.ChannelID.String()
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, c)
	signed, err := token.SignedString(s.secret)
	if err != nil {
		return "", fmt.Errorf("sign token: %w", err)
	}
	return signed, nil
}

func (s *JWTService) ValidateToken(_ context.Context, tokenStr string) (*service.TokenClaims, error) {
	token, err := jwt.ParseWithClaims(tokenStr, &customClaims{}, func(t *jwt.Token) (interface{}, error) {
		if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", t.Header["alg"])
		}
		return s.secret, nil
	})
	if err != nil {
		return nil, domainErr.New(domainErr.ErrUnauthorized, "invalid token", err)
	}

	claims, ok := token.Claims.(*customClaims)
	if !ok || !token.Valid {
		return nil, domainErr.New(domainErr.ErrUnauthorized, "invalid token claims", nil)
	}

	userID, _ := uuid.Parse(claims.UserID)
	orgID, _ := uuid.Parse(claims.OrganizationID)
	deviceID, _ := uuid.Parse(claims.DeviceID)
	handshakeID, _ := uuid.Parse(claims.HandshakeID)
	channelID, _ := uuid.Parse(claims.ChannelID)
	kind := claims.TokenKind
	if kind == "" {
		kind = service.TokenKindUser
	}

	return &service.TokenClaims{
		UserID:         userID,
		Email:          claims.Email,
		OrganizationID: orgID,
		Roles:          claims.Roles,
		Permissions:    claims.Permissions,
		TokenKind:      kind,
		DeviceID:       deviceID,
		HandshakeID:    handshakeID,
		ChannelID:      channelID,
		BarrierFP:      claims.BarrierFP,
	}, nil
}
