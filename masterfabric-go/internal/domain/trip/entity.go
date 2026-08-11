package trip

import (
	"time"

	"github.com/google/uuid"
	"github.com/leventkok/NavGo/internal/domain/places"
)

// Stop is a grounded itinerary stop (must come from Places search).
type Stop struct {
	PlaceID          string       `json:"place_id"`
	DisplayName      string       `json:"displayName"`
	FormattedAddress string       `json:"formattedAddress,omitempty"`
	Location         places.LatLng `json:"location"`
	Order            int          `json:"order"`
	Types            []string     `json:"types,omitempty"`
	GoogleMapsURI    string       `json:"googleMapsUri,omitempty"`
}

// Itinerary is a persisted client decision (LLM-agnostic).
type Itinerary struct {
	ID               uuid.UUID `json:"id"`
	UserID           uuid.UUID `json:"user_id"`
	OrganizationID   *uuid.UUID `json:"organization_id,omitempty"`
	Prompt           string    `json:"prompt"`
	Locale           string    `json:"locale"`
	Area             string    `json:"area"`
	DurationLabel    string    `json:"duration_label"`
	Model            string    `json:"model,omitempty"`
	ClientMeta       map[string]any `json:"client_meta,omitempty"`
	Stops            []Stop    `json:"stops"`
	OverviewPolyline string    `json:"overview_polyline,omitempty"`
	GoogleMapsURL    string    `json:"google_maps_url,omitempty"`
	DistanceMeters   int64     `json:"distance_meters,omitempty"`
	DurationSeconds  int64     `json:"duration_seconds,omitempty"`
	CreatedAt        time.Time `json:"created_at"`
	UpdatedAt        time.Time `json:"updated_at"`
}
