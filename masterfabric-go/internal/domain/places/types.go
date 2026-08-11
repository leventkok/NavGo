// Package places defines Google Places / Directions shaped DTOs and ports.
// Mock and Google adapters must map to these shapes so swaps stay thin.
package places

import "time"

// LatLng mirrors Google location payload.
type LatLng struct {
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
}

// Place mirrors Google Places API (New) place resource fields we rely on.
type Place struct {
	PlaceID          string   `json:"place_id"`
	DisplayName      string   `json:"displayName"`
	FormattedAddress string   `json:"formattedAddress"`
	Location         LatLng   `json:"location"`
	Types            []string `json:"types"`
	Rating           float64  `json:"rating,omitempty"`
	UserRatingCount  int      `json:"userRatingCount,omitempty"`
	GoogleMapsURI    string   `json:"googleMapsUri,omitempty"`
	BusinessStatus   string   `json:"businessStatus,omitempty"`
}

// SearchRequest is the Places text/nearby search input.
type SearchRequest struct {
	Query    string  `json:"query"`
	Area     string  `json:"area"`
	Language string  `json:"language,omitempty"`
	Lat      float64 `json:"lat,omitempty"`
	Lng      float64 `json:"lng,omitempty"`
	RadiusM  int     `json:"radius_m,omitempty"`
	MaxResults int   `json:"max_results,omitempty"`
}

// SearchResponse is a grounded place list (never LLM-invented).
type SearchResponse struct {
	Places     []Place `json:"places"`
	CacheHit   bool    `json:"cache_hit"`
	Provider   string  `json:"provider"`
	NextPageToken string `json:"nextPageToken,omitempty"`
}

// RouteLeg mirrors a Directions/Routes API leg.
type RouteLeg struct {
	StartAddress           string `json:"startAddress"`
	EndAddress             string `json:"endAddress"`
	DistanceMeters         int64  `json:"distanceMeters"`
	Duration               string `json:"duration"`
	DurationSeconds        int64  `json:"durationSeconds"`
	StartLocation          LatLng `json:"startLocation"`
	EndLocation            LatLng `json:"endLocation"`
	EncodedPolyline        string `json:"encodedPolyline,omitempty"`
}

// BuildRouteRequest asks for an optimized walking/driving day route.
type BuildRouteRequest struct {
	PlaceIDs           []string `json:"place_ids"`
	TravelMode         string   `json:"travel_mode,omitempty"` // WALK|DRIVE|BICYCLE|TRANSIT
	OptimizeWaypointOrder bool  `json:"optimize_waypoint_order"`
	Language           string   `json:"language,omitempty"`
}

// BuildRouteResponse mirrors Directions/Routes fields used by clients.
type BuildRouteResponse struct {
	OverviewPolyline string    `json:"overviewPolyline"`
	Legs             []RouteLeg `json:"legs"`
	WaypointOrder    []int     `json:"waypointOrder"`
	DistanceMeters   int64     `json:"distanceMeters"`
	DurationSeconds  int64     `json:"durationSeconds"`
	GoogleMapsURL    string    `json:"googleMapsUrl"`
	Status           string    `json:"status"`
	Provider         string    `json:"provider"`
	QuotaWarning     string    `json:"quotaWarning,omitempty"`
}

// CachedPlace is the persistence shape for places_cache.
type CachedPlace struct {
	Place
	RawJSON    []byte
	Embedding  []float32
	FetchedAt  time.Time
	ExpiresAt  time.Time
}
