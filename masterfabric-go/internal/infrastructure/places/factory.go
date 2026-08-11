package placesinfra

import (
	"github.com/leventkok/NavGo/internal/domain/places"
)

// NewClients returns Places + Directions clients.
// Empty apiKey → mock adapters. Non-empty → Google Places (New) + Routes API.
func NewClients(apiKey string, cache places.PlaceCache) (places.PlacesClient, places.DirectionsClient) {
	if apiKey == "" {
		inner := NewMockPlacesClient()
		return NewCachingPlacesClient(inner, cache), NewMockDirectionsClient()
	}
	placesClient := NewCachingPlacesClient(NewGooglePlacesClient(apiKey), cache)
	return placesClient, NewGoogleRoutesClient(apiKey)
}
