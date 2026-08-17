package dto

import (
	"encoding/json"
	"time"

	"github.com/google/uuid"
)

// HandshakeRequest starts a device auth handshake.
type HandshakeRequest struct {
	DeviceLabel string `json:"device_label"`
}

// HandshakeResponse is returned to clients before login.
type HandshakeResponse struct {
	HandshakeID string    `json:"handshake_id"`
	DeviceID    string    `json:"device_id"`
	ChannelID   string    `json:"channel_id"`
	ChannelPath string    `json:"channel_path"`
	DeviceToken string    `json:"device_token"`
	Barrier     string    `json:"barrier"`
	ExpiresAt   time.Time `json:"expires_at"`
}

// BindRequest blends user session with device handshake.
type BindRequest struct {
	HandshakeID string `json:"handshake_id" validate:"required,uuid"`
	Barrier     string `json:"barrier" validate:"required"`
}

// BindResponse returns a blended JWT for channel-bound APIs.
type BindResponse struct {
	Token       string    `json:"token"`
	TokenKind   string    `json:"token_kind"`
	ChannelID   string    `json:"channel_id"`
	ChannelPath string    `json:"channel_path"`
	ExpiresAt   time.Time `json:"expires_at"`
}

// IngestScanRequest stores an MCP/CLI security report.
type IngestScanRequest struct {
	Source     string          `json:"source"`
	ScoreGrade string          `json:"score_grade"`
	ScoreValue int             `json:"score_value"`
	Report     json.RawMessage `json:"report" validate:"required"`
}

// ScanInfo is a list item for security scans.
type ScanInfo struct {
	ID             uuid.UUID       `json:"id"`
	OrganizationID *uuid.UUID      `json:"organization_id,omitempty"`
	UserID         *uuid.UUID      `json:"user_id,omitempty"`
	Source         string          `json:"source"`
	ScoreGrade     string          `json:"score_grade,omitempty"`
	ScoreValue     int             `json:"score_value,omitempty"`
	Report         json.RawMessage `json:"report"`
	CreatedAt      time.Time       `json:"created_at"`
}
