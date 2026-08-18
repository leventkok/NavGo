package dto

import (
	"github.com/google/uuid"
	"github.com/leventkok/NavGo/internal/domain/places"
	"github.com/leventkok/NavGo/internal/domain/trip"
)

type SearchPlacesRequest struct {
	Query      string  `json:"query" validate:"required"`
	Area       string  `json:"area"`
	Language   string  `json:"language"`
	Lat        float64 `json:"lat"`
	Lng        float64 `json:"lng"`
	RadiusM    int     `json:"radius_m"`
	MaxResults int     `json:"max_results"`
}

type BuildRouteRequest struct {
	PlaceIDs              []string `json:"place_ids" validate:"required,min=1"`
	TravelMode            string   `json:"travel_mode"`
	OptimizeWaypointOrder bool     `json:"optimize_waypoint_order"`
	Language              string   `json:"language"`
	OriginLat             float64  `json:"origin_lat"`
	OriginLng             float64  `json:"origin_lng"`
}

type StopInput struct {
	PlaceID          string        `json:"place_id" validate:"required"`
	DisplayName      string        `json:"displayName"`
	FormattedAddress string        `json:"formattedAddress"`
	Location         places.LatLng `json:"location"`
	Order            int           `json:"order"`
	Types            []string      `json:"types"`
	GoogleMapsURI    string        `json:"googleMapsUri"`
}

type SaveItineraryRequest struct {
	Prompt           string         `json:"prompt" validate:"required"`
	Locale           string         `json:"locale"`
	Area             string         `json:"area"`
	DurationLabel    string         `json:"duration_label"`
	Model            string         `json:"model"`
	ClientMeta       map[string]any `json:"client_meta"`
	Stops            []StopInput    `json:"stops" validate:"required,min=1"`
	OverviewPolyline string         `json:"overview_polyline"`
	GoogleMapsURL    string         `json:"google_maps_url"`
	DistanceMeters   int64          `json:"distance_meters"`
	DurationSeconds  int64          `json:"duration_seconds"`
	OrganizationID   *uuid.UUID     `json:"organization_id"`
}

type PlanDayRequest struct {
	Prompt                string `json:"prompt" validate:"required"`
	Area                  string `json:"area" validate:"required"`
	Locale                string `json:"locale"`
	DurationLabel         string `json:"duration_label"`
	TravelMode            string `json:"travel_mode"`
	OptimizeWaypointOrder bool   `json:"optimize_waypoint_order"`
	MaxStops              int    `json:"max_stops"`
	Save                  bool   `json:"save"`
	Model                 string `json:"model"`
	UserID                uuid.UUID `json:"-"`
}

type PlanDayResponse struct {
	Search     *places.SearchResponse     `json:"search"`
	Route      *places.BuildRouteResponse `json:"route"`
	Itinerary  *trip.Itinerary            `json:"itinerary,omitempty"`
}
