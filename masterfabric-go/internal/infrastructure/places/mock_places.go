package placesinfra

import (
	"context"
	"fmt"
	"strings"

	"github.com/leventkok/NavGo/internal/domain/places"
)

// MockPlacesClient returns Kaleiçi / Antalya grounded fixtures in Google shape.
type MockPlacesClient struct{}

func NewMockPlacesClient() *MockPlacesClient {
	return &MockPlacesClient{}
}

func (m *MockPlacesClient) catalog() []places.Place {
	return []places.Place{
		{
			PlaceID:          "ChIJkaleici_hadrian_gate",
			DisplayName:      "Hadrian's Gate",
			FormattedAddress: "Hadrian Kapısı, Kaleiçi, Antalya, Türkiye",
			Location:         places.LatLng{Latitude: 36.8854, Longitude: 30.7087},
			Types:            []string{"tourist_attraction", "point_of_interest"},
			Rating:           4.7,
			UserRatingCount:  12840,
			GoogleMapsURI:    "https://maps.google.com/?cid=hadrian",
			BusinessStatus:   "OPERATIONAL",
		},
		{
			PlaceID:          "ChIJkaleici_antalya_museum",
			DisplayName:      "Antalya Museum",
			FormattedAddress: "Konyaaltı Cd., Antalya, Türkiye",
			Location:         places.LatLng{Latitude: 36.8849, Longitude: 30.6695},
			Types:            []string{"museum", "tourist_attraction"},
			Rating:           4.6,
			UserRatingCount:  9200,
			GoogleMapsURI:    "https://maps.google.com/?cid=museum",
			BusinessStatus:   "OPERATIONAL",
		},
		{
			PlaceID:          "ChIJkaleici_yivli_minare",
			DisplayName:      "Yivli Minare Mosque",
			FormattedAddress: "Kaleiçi, Antalya, Türkiye",
			Location:         places.LatLng{Latitude: 36.8867, Longitude: 30.7049},
			Types:            []string{"mosque", "tourist_attraction"},
			Rating:           4.7,
			UserRatingCount:  15400,
			GoogleMapsURI:    "https://maps.google.com/?cid=yivli",
			BusinessStatus:   "OPERATIONAL",
		},
		{
			PlaceID:          "ChIJkaleici_old_harbor",
			DisplayName:      "Antalya Old Harbor",
			FormattedAddress: "Kaleiçi Marina, Antalya, Türkiye",
			Location:         places.LatLng{Latitude: 36.8841, Longitude: 30.7022},
			Types:            []string{"tourist_attraction", "harbor"},
			Rating:           4.8,
			UserRatingCount:  21000,
			GoogleMapsURI:    "https://maps.google.com/?cid=harbor",
			BusinessStatus:   "OPERATIONAL",
		},
		{
			PlaceID:          "ChIJkaleici_kesik_minare",
			DisplayName:      "Kesik Minare",
			FormattedAddress: "Kaleiçi, Antalya, Türkiye",
			Location:         places.LatLng{Latitude: 36.8832, Longitude: 30.7061},
			Types:            []string{"tourist_attraction", "church"},
			Rating:           4.5,
			UserRatingCount:  4100,
			GoogleMapsURI:    "https://maps.google.com/?cid=kesik",
			BusinessStatus:   "OPERATIONAL",
		},
		{
			PlaceID:          "ChIJkaleici_hava_raki",
			DisplayName:      "Havana Social Club (Kaleiçi)",
			FormattedAddress: "Kaleiçi, Antalya, Türkiye",
			Location:         places.LatLng{Latitude: 36.8859, Longitude: 30.7055},
			Types:            []string{"restaurant", "cafe", "food"},
			Rating:           4.4,
			UserRatingCount:  1800,
			GoogleMapsURI:    "https://maps.google.com/?cid=havana",
			BusinessStatus:   "OPERATIONAL",
		},
	}
}

func (m *MockPlacesClient) Search(_ context.Context, req places.SearchRequest) (*places.SearchResponse, error) {
	q := strings.ToLower(strings.TrimSpace(req.Query + " " + req.Area))
	all := m.catalog()
	var out []places.Place
	for _, p := range all {
		hay := strings.ToLower(p.DisplayName + " " + p.FormattedAddress + " " + strings.Join(p.Types, " "))
		if q == "" || strings.Contains(hay, "kale") || strings.Contains(q, "antalya") || strings.Contains(q, "kaleiçi") || strings.Contains(q, "kaleici") || strings.Contains(hay, strings.ToLower(req.Query)) {
			out = append(out, p)
		}
	}
	if len(out) == 0 {
		out = all
	}
	max := req.MaxResults
	if max <= 0 || max > len(out) {
		max = len(out)
	}
	return &places.SearchResponse{
		Places:   out[:max],
		CacheHit: false,
		Provider: "mock",
	}, nil
}

func (m *MockPlacesClient) GetByPlaceID(_ context.Context, placeID string) (*places.Place, error) {
	for _, p := range m.catalog() {
		if p.PlaceID == placeID {
			cp := p
			return &cp, nil
		}
	}
	return nil, fmt.Errorf("place not found: %s", placeID)
}
