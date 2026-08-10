package placesinfra

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/leventkok/NavGo/internal/domain/places"
	domainErr "github.com/leventkok/NavGo/internal/shared/errors"
)

const (
	routesURL       = "https://routes.googleapis.com/directions/v2:computeRoutes"
	routesFieldMask = "routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline,routes.legs.distanceMeters,routes.legs.duration,routes.legs.startLocation,routes.legs.endLocation,routes.legs.polyline,routes.optimizedIntermediateWaypointIndex"
)

// GoogleRoutesClient calls Routes API computeRoutes.
type GoogleRoutesClient struct {
	apiKey string
	http   *http.Client
}

func NewGoogleRoutesClient(apiKey string) *GoogleRoutesClient {
	return &GoogleRoutesClient{apiKey: apiKey, http: newGoogleHTTPClient()}
}

type routesLatLng struct {
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
}

type routesLocation struct {
	LatLng *routesLatLng `json:"latLng,omitempty"`
}

// routesWaypoint matches Routes API Waypoint: placeId is a sibling of location, not nested in it.
type routesWaypoint struct {
	PlaceID  string          `json:"placeId,omitempty"`
	Location *routesLocation `json:"location,omitempty"`
}

type routesRequest struct {
	Origin                   routesWaypoint   `json:"origin"`
	Destination              routesWaypoint   `json:"destination"`
	Intermediates            []routesWaypoint `json:"intermediates,omitempty"`
	TravelMode               string           `json:"travelMode"`
	OptimizeWaypointOrder    bool             `json:"optimizeWaypointOrder,omitempty"`
	LanguageCode             string           `json:"languageCode,omitempty"`
	ComputeAlternativeRoutes bool             `json:"computeAlternativeRoutes"`
}

type routesResponse struct {
	Routes []struct {
		DistanceMeters int64  `json:"distanceMeters"`
		Duration       string `json:"duration"`
		Polyline       *struct {
			EncodedPolyline string `json:"encodedPolyline"`
		} `json:"polyline"`
		OptimizedIntermediateWaypointIndex []int `json:"optimizedIntermediateWaypointIndex"`
		Legs                               []struct {
			DistanceMeters int64  `json:"distanceMeters"`
			Duration       string `json:"duration"`
			StartLocation  *struct {
				LatLng *routesLatLng `json:"latLng"`
			} `json:"startLocation"`
			EndLocation *struct {
				LatLng *routesLatLng `json:"latLng"`
			} `json:"endLocation"`
			Polyline *struct {
				EncodedPolyline string `json:"encodedPolyline"`
			} `json:"polyline"`
		} `json:"legs"`
	} `json:"routes"`
}

func (c *GoogleRoutesClient) BuildRoute(ctx context.Context, req places.BuildRouteRequest, resolved []places.Place) (*places.BuildRouteResponse, error) {
	if len(resolved) < 2 {
		return nil, domainErr.New(domainErr.ErrValidation, "need at least 2 grounded places for a route", nil)
	}

	mode := mapTravelMode(req.TravelMode)
	lang := req.Language
	if lang == "" {
		lang = "tr"
	}

	origin := waypointFromPlace(resolved[0])
	dest := waypointFromPlace(resolved[len(resolved)-1])
	var mids []routesWaypoint
	for i := 1; i < len(resolved)-1; i++ {
		mids = append(mids, waypointFromPlace(resolved[i]))
	}

	body, _ := json.Marshal(routesRequest{
		Origin:                   origin,
		Destination:              dest,
		Intermediates:            mids,
		TravelMode:               mode,
		OptimizeWaypointOrder:    req.OptimizeWaypointOrder && len(mids) > 0,
		LanguageCode:             lang,
		ComputeAlternativeRoutes: false,
	})

	httpReq, err := http.NewRequestWithContext(ctx, http.MethodPost, routesURL, bytes.NewReader(body))
	if err != nil {
		return nil, domainErr.New(domainErr.ErrInternal, "failed to build routes request", err)
	}
	httpReq.GetBody = func() (io.ReadCloser, error) {
		return io.NopCloser(bytes.NewReader(body)), nil
	}
	httpReq.Header.Set("Content-Type", "application/json")
	httpReq.Header.Set("X-Goog-Api-Key", c.apiKey)
	httpReq.Header.Set("X-Goog-FieldMask", routesFieldMask)

	resp, raw, err := doGoogleRequest(ctx, c.http, httpReq)
	if err != nil {
		return nil, domainErr.New(domainErr.ErrInternal, "routes request failed", err)
	}
	if resp.StatusCode >= 300 {
		return nil, domainErr.New(domainErr.ErrBadRequest, fmt.Sprintf("routes http %d: %s", resp.StatusCode, truncate(string(raw), 400)), nil)
	}

	var parsed routesResponse
	if err := json.Unmarshal(raw, &parsed); err != nil {
		return nil, domainErr.New(domainErr.ErrInternal, "routes decode failed", err)
	}
	if len(parsed.Routes) == 0 {
		return nil, domainErr.New(domainErr.ErrNotFound, "no route found", nil)
	}
	route := parsed.Routes[0]

	order := make([]int, len(resolved))
	for i := range order {
		order[i] = i
	}
	if len(route.OptimizedIntermediateWaypointIndex) > 0 {
		// Google returns order of intermediates only; rebuild full order: origin + opts + dest.
		order = []int{0}
		for _, idx := range route.OptimizedIntermediateWaypointIndex {
			order = append(order, idx+1)
		}
		order = append(order, len(resolved)-1)
	}

	legs := make([]places.RouteLeg, 0, len(route.Legs))
	for i, leg := range route.Legs {
		startAddr, endAddr := "", ""
		if i < len(resolved)-1 {
			si, ei := orderIndex(order, i), orderIndex(order, i+1)
			if si >= 0 && si < len(resolved) {
				startAddr = resolved[si].FormattedAddress
			}
			if ei >= 0 && ei < len(resolved) {
				endAddr = resolved[ei].FormattedAddress
			}
		}
		var start, end places.LatLng
		if leg.StartLocation != nil && leg.StartLocation.LatLng != nil {
			start = places.LatLng{Latitude: leg.StartLocation.LatLng.Latitude, Longitude: leg.StartLocation.LatLng.Longitude}
		}
		if leg.EndLocation != nil && leg.EndLocation.LatLng != nil {
			end = places.LatLng{Latitude: leg.EndLocation.LatLng.Latitude, Longitude: leg.EndLocation.LatLng.Longitude}
		}
		poly := ""
		if leg.Polyline != nil {
			poly = leg.Polyline.EncodedPolyline
		}
		legs = append(legs, places.RouteLeg{
			StartAddress:    startAddr,
			EndAddress:      endAddr,
			DistanceMeters:  leg.DistanceMeters,
			Duration:        leg.Duration,
			DurationSeconds: parseDurationSeconds(leg.Duration),
			StartLocation:   start,
			EndLocation:     end,
			EncodedPolyline: poly,
		})
	}

	overview := ""
	if route.Polyline != nil {
		overview = route.Polyline.EncodedPolyline
	}

	ordered := make([]places.Place, 0, len(order))
	for _, idx := range order {
		if idx >= 0 && idx < len(resolved) {
			ordered = append(ordered, resolved[idx])
		}
	}
	if len(ordered) == 0 {
		ordered = resolved
	}

	return &places.BuildRouteResponse{
		OverviewPolyline: overview,
		Legs:             legs,
		WaypointOrder:    order,
		DistanceMeters:   route.DistanceMeters,
		DurationSeconds:  parseDurationSeconds(route.Duration),
		GoogleMapsURL:    buildGoogleMapsURL(ordered, mode),
		Status:           "OK",
		Provider:         "google",
	}, nil
}

func waypointFromPlace(p places.Place) routesWaypoint {
	if p.PlaceID != "" {
		return routesWaypoint{PlaceID: p.PlaceID}
	}
	return routesWaypoint{Location: &routesLocation{LatLng: &routesLatLng{
		Latitude: p.Location.Latitude, Longitude: p.Location.Longitude,
	}}}
}

func mapTravelMode(mode string) string {
	switch strings.ToUpper(strings.TrimSpace(mode)) {
	case "DRIVE", "DRIVING", "CAR":
		return "DRIVE"
	case "BICYCLE", "BIKE":
		return "BICYCLE"
	case "TRANSIT":
		return "TRANSIT"
	default:
		return "WALK"
	}
}

func parseDurationSeconds(d string) int64 {
	// Routes API returns e.g. "123s"
	d = strings.TrimSpace(d)
	if strings.HasSuffix(d, "s") {
		if n, err := strconv.ParseInt(strings.TrimSuffix(d, "s"), 10, 64); err == nil {
			return n
		}
	}
	if dur, err := time.ParseDuration(d); err == nil {
		return int64(dur.Seconds())
	}
	return 0
}

func orderIndex(order []int, i int) int {
	if i < 0 || i >= len(order) {
		return i
	}
	return order[i]
}
