package placesinfra

import (
	"github.com/leventkok/NavGo/internal/domain/places"
)

// NewClients returns Places + Directions clients.
// When apiKey is empty, mock adapters are used (Google-shaped DTOs).
// Non-empty key is reserved for the future Google adapter swap PR.
func NewClients(apiKey string, cache places.PlaceCache) (places.PlacesClient, places.DirectionsClient) {
	_ = apiKey // Google adapter not wired yet; mock keeps the Google response shape.
	inner := NewMockPlacesClient()
	return NewCachingPlacesClient(inner, cache), NewMockDirectionsClient()
}
