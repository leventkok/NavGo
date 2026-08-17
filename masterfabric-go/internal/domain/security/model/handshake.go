package model

import (
	"time"

	"github.com/google/uuid"
)

// Handshake is a pre-auth device barrier used to bind a later login to a channel.
type Handshake struct {
	ID          uuid.UUID  `json:"id"`
	DeviceID    uuid.UUID  `json:"device_id"`
	ChannelID   uuid.UUID  `json:"channel_id"`
	BarrierHash string     `json:"-"`
	BarrierHint string     `json:"-"`
	BoundUserID *uuid.UUID `json:"bound_user_id,omitempty"`
	ExpiresAt   time.Time  `json:"expires_at"`
	CreatedAt   time.Time  `json:"created_at"`
	BoundAt     *time.Time `json:"bound_at,omitempty"`
}

// SecurityScan is a persisted MCP/CLI security report.
type SecurityScan struct {
	ID             uuid.UUID  `json:"id"`
	OrganizationID *uuid.UUID `json:"organization_id,omitempty"`
	UserID         *uuid.UUID `json:"user_id,omitempty"`
	Source         string     `json:"source"`
	ScoreGrade     string     `json:"score_grade,omitempty"`
	ScoreValue     int        `json:"score_value,omitempty"`
	Report         []byte     `json:"report"`
	CreatedAt      time.Time  `json:"created_at"`
}
