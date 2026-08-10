package placesinfra

import (
	"context"
	"fmt"
	"math"
	"net/url"
	"strings"

	"github.com/leventkok/NavGo/internal/domain/places"
)

// MockDirectionsClient builds a deterministic day route in Google Directions shape.
type MockDirectionsClient struct{}

func NewMockDirectionsClient() *MockDirectionsClient {
	return &MockDirectionsClient{}
}

func (m *MockDirectionsClient) BuildRoute(_ context.Context, req places.BuildRouteRequest, resolved []places.Place) (*places.BuildRouteResponse, error) {
	if len(resolved) < 2 {
		return nil, fmt.Errorf("need at least 2 grounded places for a route")
	}

	order := make([]int, len(resolved))
	for i := range order {
		order[i] = i
	}
	if req.OptimizeWaypointOrder && len(resolved) > 2 {
		order = nearestNeighborOrder(resolved)
	}

	ordered := make([]places.Place, len(order))
	for i, idx := range order {
		ordered[i] = resolved[idx]
	}

	var legs []places.RouteLeg
	var totalDist, totalDur int64
	for i := 0; i < len(ordered)-1; i++ {
		a, b := ordered[i], ordered[i+1]
		dist := haversineMeters(a.Location, b.Location)
		dur := int64(float64(dist) / 1.2)
		legs = append(legs, places.RouteLeg{
			StartAddress:    a.FormattedAddress,
			EndAddress:      b.FormattedAddress,
			DistanceMeters:  dist,
			Duration:        fmt.Sprintf("%ds", dur),
			DurationSeconds: dur,
			StartLocation:   a.Location,
			EndLocation:     b.Location,
			EncodedPolyline: mockPolyline(a.Location, b.Location),
		})
		totalDist += dist
		totalDur += dur
	}

	return &places.BuildRouteResponse{
		OverviewPolyline: mockPolyline(ordered[0].Location, ordered[len(ordered)-1].Location),
		Legs:             legs,
		WaypointOrder:    order,
		DistanceMeters:   totalDist,
		DurationSeconds:  totalDur,
		GoogleMapsURL:    buildGoogleMapsURL(ordered, req.TravelMode),
		Status:           "OK",
		Provider:         "mock",
	}, nil
}

func nearestNeighborOrder(ps []places.Place) []int {
	n := len(ps)
	used := make([]bool, n)
	order := make([]int, 0, n)
	cur := 0
	used[cur] = true
	order = append(order, cur)
	for len(order) < n {
		best, bestDist := -1, int64(math.MaxInt64)
		for i := 0; i < n; i++ {
			if used[i] {
				continue
			}
			d := haversineMeters(ps[cur].Location, ps[i].Location)
			if d < bestDist {
				bestDist = d
				best = i
			}
		}
		used[best] = true
		order = append(order, best)
		cur = best
	}
	return order
}

func haversineMeters(a, b places.LatLng) int64 {
	const R = 6371000.0
	toRad := func(d float64) float64 { return d * math.Pi / 180 }
	dLat := toRad(b.Latitude - a.Latitude)
	dLon := toRad(b.Longitude - a.Longitude)
	lat1 := toRad(a.Latitude)
	lat2 := toRad(b.Latitude)
	h := math.Sin(dLat/2)*math.Sin(dLat/2) + math.Cos(lat1)*math.Cos(lat2)*math.Sin(dLon/2)*math.Sin(dLon/2)
	c := 2 * math.Atan2(math.Sqrt(h), math.Sqrt(1-h))
	return int64(R * c)
}

func mockPolyline(a, b places.LatLng) string {
	// Not a real encoded polyline; stable mock token for clients/tests.
	return fmt.Sprintf("mock_poly_%.4f_%.4f_%.4f_%.4f", a.Latitude, a.Longitude, b.Latitude, b.Longitude)
}

func buildGoogleMapsURL(ordered []places.Place, mode string) string {
	if mode == "" {
		mode = "walking"
	}
	origin := fmt.Sprintf("%f,%f", ordered[0].Location.Latitude, ordered[0].Location.Longitude)
	dest := fmt.Sprintf("%f,%f", ordered[len(ordered)-1].Location.Latitude, ordered[len(ordered)-1].Location.Longitude)
	var waypoints []string
	for i := 1; i < len(ordered)-1; i++ {
		waypoints = append(waypoints, fmt.Sprintf("%f,%f", ordered[i].Location.Latitude, ordered[i].Location.Longitude))
	}
	u := url.URL{Scheme: "https", Host: "www.google.com", Path: "/maps/dir/"}
	q := u.Query()
	q.Set("api", "1")
	q.Set("origin", origin)
	q.Set("destination", dest)
	q.Set("travelmode", strings.ToLower(mode))
	if len(waypoints) > 0 {
		q.Set("waypoints", strings.Join(waypoints, "|"))
	}
	u.RawQuery = q.Encode()
	return u.String()
}
