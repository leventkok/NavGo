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
	routesURL = "https://routes.googleapis.com/directions/v2:computeRoutes"
	routesFieldMask = "routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline," +
		"routes.legs.distanceMeters,routes.legs.duration,routes.legs.startLocation,routes.legs.endLocation," +
		"routes.legs.polyline," +
		"routes.legs.steps.travelMode,routes.legs.steps.navigationInstruction," +
		"routes.legs.steps.distanceMeters,routes.legs.steps.staticDuration," +
		"routes.legs.steps.polyline,routes.legs.steps.startLocation,routes.legs.steps.endLocation," +
		"routes.legs.steps.transitDetails," +
		"routes.optimizedIntermediateWaypointIndex"
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

type routesTransitPrefs struct {
	RoutingPreference  string   `json:"routingPreference,omitempty"`
	AllowedTravelModes []string `json:"allowedTravelModes,omitempty"`
}

type routesRequest struct {
	Origin                   routesWaypoint      `json:"origin"`
	Destination              routesWaypoint      `json:"destination"`
	Intermediates            []routesWaypoint    `json:"intermediates,omitempty"`
	TravelMode               string              `json:"travelMode"`
	OptimizeWaypointOrder    bool                `json:"optimizeWaypointOrder,omitempty"`
	LanguageCode             string              `json:"languageCode,omitempty"`
	RegionCode               string              `json:"regionCode,omitempty"`
	ComputeAlternativeRoutes bool                `json:"computeAlternativeRoutes"`
	DepartureTime            string              `json:"departureTime,omitempty"`
	TransitPreferences       *routesTransitPrefs `json:"transitPreferences,omitempty"`
}

// googLocalizedText accepts both "Bus" and {"text":"Bus"} (Routes API vehicle.name).
type googLocalizedText struct {
	Text string `json:"text"`
}

func (l *googLocalizedText) UnmarshalJSON(data []byte) error {
	if len(data) == 0 || string(data) == "null" {
		return nil
	}
	switch data[0] {
	case '"':
		return json.Unmarshal(data, &l.Text)
	case '{':
		var obj struct {
			Text string `json:"text"`
		}
		if err := json.Unmarshal(data, &obj); err != nil {
			return err
		}
		l.Text = obj.Text
		return nil
	default:
		return nil
	}
}

type routesTransitStop struct {
	Name     string `json:"name"`
	Location *struct {
		LatLng *routesLatLng `json:"latLng"`
	} `json:"location"`
}

type routesTransitDetails struct {
	Headsign    string `json:"headsign"`
	StopCount   int    `json:"stopCount"`
	TransitLine *struct {
		Name      string `json:"name"`
		NameShort string `json:"nameShort"`
		Vehicle   *struct {
			Name googLocalizedText `json:"name"`
			Type string            `json:"type"`
		} `json:"vehicle"`
	} `json:"transitLine"`
	StopDetails *struct {
		DepartureStop *routesTransitStop `json:"departureStop"`
		ArrivalStop   *routesTransitStop `json:"arrivalStop"`
	} `json:"stopDetails"`
}

type routesStep struct {
	TravelMode            string `json:"travelMode"`
	DistanceMeters        int64  `json:"distanceMeters"`
	StaticDuration        string `json:"staticDuration"`
	NavigationInstruction *struct {
		Instructions string `json:"instructions"`
	} `json:"navigationInstruction"`
	Polyline *struct {
		EncodedPolyline string `json:"encodedPolyline"`
	} `json:"polyline"`
	TransitDetails *routesTransitDetails `json:"transitDetails"`
}

type routesLeg struct {
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
	Steps []routesStep `json:"steps"`
}

type routesAPIRoute struct {
	DistanceMeters                     int64  `json:"distanceMeters"`
	Duration                           string `json:"duration"`
	Polyline                           *struct {
		EncodedPolyline string `json:"encodedPolyline"`
	} `json:"polyline"`
	OptimizedIntermediateWaypointIndex []int       `json:"optimizedIntermediateWaypointIndex"`
	Legs                               []routesLeg `json:"legs"`
}

type routesResponse struct {
	Routes []routesAPIRoute `json:"routes"`
}

func (c *GoogleRoutesClient) BuildRoute(ctx context.Context, req places.BuildRouteRequest, resolved []places.Place) (*places.BuildRouteResponse, error) {
	hasOrigin := req.OriginLat != 0 || req.OriginLng != 0
	minPlaces := 2
	if hasOrigin {
		minPlaces = 1
	}
	if len(resolved) < minPlaces {
		return nil, domainErr.New(domainErr.ErrValidation, "need at least 2 grounded places for a route", nil)
	}

	mode := mapTravelMode(req.TravelMode)
	lang := req.Language
	if lang == "" {
		lang = "tr"
	}

	// TRANSIT does not support intermediate waypoints — build leg-by-leg.
	if mode == "TRANSIT" && (hasOrigin && len(resolved) > 1 || len(resolved) > 2) {
		return c.buildSequentialRoute(ctx, req, resolved, mode, lang, hasOrigin)
	}

	origin := waypointForMode(resolved[0], mode)
	dest := waypointForMode(resolved[len(resolved)-1], mode)
	var mids []routesWaypoint
	for i := 1; i < len(resolved)-1; i++ {
		mids = append(mids, waypointForMode(resolved[i], mode))
	}
	if hasOrigin {
		origin = routesWaypoint{Location: &routesLocation{LatLng: &routesLatLng{
			Latitude: req.OriginLat, Longitude: req.OriginLng,
		}}}
		if len(resolved) == 1 {
			dest = waypointForMode(resolved[0], mode)
			mids = nil
		} else {
			dest = waypointForMode(resolved[len(resolved)-1], mode)
			mids = make([]routesWaypoint, 0, len(resolved)-1)
			for i := 0; i < len(resolved)-1; i++ {
				mids = append(mids, waypointForMode(resolved[i], mode))
			}
		}
	}

	optimize := req.OptimizeWaypointOrder && len(mids) > 0 && !hasOrigin
	if mode == "TRANSIT" {
		optimize = false
	}

	resp, raw, err := c.computeRoutes(ctx, origin, dest, mids, mode, optimize, lang, "")
	if err != nil {
		return nil, err
	}
	if resp.StatusCode == http.StatusOK {
		var probe routesResponse
		if json.Unmarshal(raw, &probe) == nil && len(probe.Routes) == 0 && mode == "BICYCLE" {
			mode = "WALK"
			optimize = req.OptimizeWaypointOrder && len(mids) > 0 && !hasOrigin
			resp, raw, err = c.computeRoutes(ctx, origin, dest, mids, mode, optimize, lang, "")
			if err != nil {
				return nil, err
			}
		}
	}
	if resp.StatusCode >= 300 {
		return nil, domainErr.New(domainErr.ErrBadRequest, fmt.Sprintf("routes http %d: %s", resp.StatusCode, truncate(string(raw), 400)), nil)
	}

	var parsed routesResponse
	if err := json.Unmarshal(raw, &parsed); err != nil {
		return nil, domainErr.New(domainErr.ErrInternal, "routes decode failed", err)
	}
	if len(parsed.Routes) == 0 && mode == "BICYCLE" {
		mode = "WALK"
		optimize = req.OptimizeWaypointOrder && len(mids) > 0 && !hasOrigin
		resp, raw, err = c.computeRoutes(ctx, origin, dest, mids, mode, optimize, lang, "")
		if err != nil {
			return nil, err
		}
		if resp.StatusCode >= 300 {
			return nil, domainErr.New(domainErr.ErrBadRequest, fmt.Sprintf("routes http %d: %s", resp.StatusCode, truncate(string(raw), 400)), nil)
		}
		if err := json.Unmarshal(raw, &parsed); err != nil {
			return nil, domainErr.New(domainErr.ErrInternal, "routes decode failed", err)
		}
	}
	if len(parsed.Routes) == 0 {
		return nil, domainErr.New(domainErr.ErrNotFound, "no route found", nil)
	}

	order := make([]int, len(resolved))
	for i := range order {
		order[i] = i
	}
	route := pickBestRoute(parsed.Routes)
	if mode == "TRANSIT" && !routeHasTransit(route) {
		if altResp, altRaw, altErr := c.computeRoutes(ctx, origin, dest, mids, mode, optimize, lang, "FEWER_TRANSFERS"); altErr == nil && altResp.StatusCode < 300 {
			var altParsed routesResponse
			if json.Unmarshal(altRaw, &altParsed) == nil && len(altParsed.Routes) > 0 {
				altRoute := pickBestRoute(altParsed.Routes)
				if routeHasTransit(altRoute) {
					route = altRoute
				}
			}
		}
	}
	if !hasOrigin && len(route.OptimizedIntermediateWaypointIndex) > 0 {
		order = []int{0}
		for _, idx := range route.OptimizedIntermediateWaypointIndex {
			order = append(order, idx+1)
		}
		order = append(order, len(resolved)-1)
	}

	legs := parseRouteLegs(route.Legs, resolved, order)
	overview := ""
	if route.Polyline != nil {
		overview = route.Polyline.EncodedPolyline
	}

	ordered := orderedPlaces(resolved, order)
	return &places.BuildRouteResponse{
		OverviewPolyline: overview,
		Legs:             legs,
		WaypointOrder:    order,
		DistanceMeters:   route.DistanceMeters,
		DurationSeconds:  parseDurationSeconds(route.Duration),
		GoogleMapsURL:    buildGoogleMapsURL(ordered, mode),
		Status:           "OK",
		Provider:         "google",
		TransitAvailable: legsHaveTransit(legs),
	}, nil
}

func (c *GoogleRoutesClient) buildSequentialRoute(
	ctx context.Context,
	req places.BuildRouteRequest,
	resolved []places.Place,
	mode, lang string,
	hasOrigin bool,
) (*places.BuildRouteResponse, error) {
	points := make([]routesWaypoint, 0, len(resolved)+1)
	if hasOrigin {
		points = append(points, routesWaypoint{Location: &routesLocation{LatLng: &routesLatLng{
			Latitude: req.OriginLat, Longitude: req.OriginLng,
		}}})
	}
	for _, p := range resolved {
		points = append(points, waypointForMode(p, mode))
	}
	if len(points) < 2 {
		return nil, domainErr.New(domainErr.ErrValidation, "need at least 2 points for sequential route", nil)
	}

	var (
		allLegs          []places.RouteLeg
		totalDist        int64
		totalDur         int64
		overviewPolyline string
	)
	for i := 0; i < len(points)-1; i++ {
		resp, raw, err := c.computeRoutes(ctx, points[i], points[i+1], nil, mode, false, lang, "")
		if err != nil {
			return nil, err
		}
		if resp.StatusCode >= 300 {
			return nil, domainErr.New(domainErr.ErrBadRequest, fmt.Sprintf("routes http %d: %s", resp.StatusCode, truncate(string(raw), 400)), nil)
		}
		var parsed routesResponse
		if err := json.Unmarshal(raw, &parsed); err != nil {
			return nil, domainErr.New(domainErr.ErrInternal, "routes decode failed", err)
		}
		if len(parsed.Routes) == 0 {
			continue
		}
		r := pickBestRoute(parsed.Routes)
		totalDist += r.DistanceMeters
		totalDur += parseDurationSeconds(r.Duration)
		if r.Polyline != nil && r.Polyline.EncodedPolyline != "" {
			if overviewPolyline == "" {
				overviewPolyline = r.Polyline.EncodedPolyline
			}
		}
		order := []int{i, i + 1}
		allLegs = append(allLegs, parseRouteLegs(r.Legs, resolved, order)...)
	}

	order := make([]int, len(resolved))
	for i := range order {
		order[i] = i
	}
	return &places.BuildRouteResponse{
		OverviewPolyline: overviewPolyline,
		Legs:             allLegs,
		WaypointOrder:    order,
		DistanceMeters:   totalDist,
		DurationSeconds:  totalDur,
		GoogleMapsURL:    buildGoogleMapsURL(resolved, mode),
		Status:           "OK",
		Provider:         "google",
		TransitAvailable: legsHaveTransit(allLegs),
	}, nil
}

func parseRouteLegs(rawLegs []routesLeg, resolved []places.Place, order []int) []places.RouteLeg {
	legs := make([]places.RouteLeg, 0, len(rawLegs))
	for i, leg := range rawLegs {
		startAddr, endAddr := "", ""
		if i < len(order)-1 {
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
		steps := parseRouteSteps(leg.Steps)
		legs = append(legs, places.RouteLeg{
			StartAddress:    startAddr,
			EndAddress:      endAddr,
			DistanceMeters:  leg.DistanceMeters,
			Duration:        leg.Duration,
			DurationSeconds: parseDurationSeconds(leg.Duration),
			StartLocation:   start,
			EndLocation:     end,
			EncodedPolyline: poly,
			Steps:           steps,
		})
	}
	return legs
}

func parseRouteSteps(raw []routesStep) []places.RouteStep {
	out := make([]places.RouteStep, 0, len(raw))
	for _, step := range raw {
		instructions := ""
		if step.NavigationInstruction != nil {
			instructions = step.NavigationInstruction.Instructions
		}
		rs := places.RouteStep{
			TravelMode:      step.TravelMode,
			Instructions:    instructions,
			DistanceMeters:  step.DistanceMeters,
			DurationSeconds: parseDurationSeconds(step.StaticDuration),
		}
		if step.Polyline != nil {
			rs.EncodedPolyline = step.Polyline.EncodedPolyline
		}
		if step.TransitDetails != nil {
			td := step.TransitDetails
			rs.Headsign = td.Headsign
			rs.StopCount = td.StopCount
			if td.TransitLine != nil {
				line := td.TransitLine.NameShort
				if line == "" {
					line = td.TransitLine.Name
				}
				rs.TransitLine = line
				if td.TransitLine.Vehicle != nil {
					rs.TransitVehicle = td.TransitLine.Vehicle.Name.Text
					if rs.TransitVehicle == "" {
						rs.TransitVehicle = td.TransitLine.Vehicle.Type
					}
				}
			}
			if td.StopDetails != nil {
				if td.StopDetails.DepartureStop != nil {
					dep := td.StopDetails.DepartureStop
					rs.DepartureStop = dep.Name
					if dep.Location != nil && dep.Location.LatLng != nil {
						rs.DepartureLat = dep.Location.LatLng.Latitude
						rs.DepartureLng = dep.Location.LatLng.Longitude
					}
				}
				if td.StopDetails.ArrivalStop != nil {
					arr := td.StopDetails.ArrivalStop
					rs.ArrivalStop = arr.Name
					if arr.Location != nil && arr.Location.LatLng != nil {
						rs.ArrivalLat = arr.Location.LatLng.Latitude
						rs.ArrivalLng = arr.Location.LatLng.Longitude
					}
				}
			}
		}
		out = append(out, rs)
	}
	return out
}

func orderedPlaces(resolved []places.Place, order []int) []places.Place {
	ordered := make([]places.Place, 0, len(order))
	for _, idx := range order {
		if idx >= 0 && idx < len(resolved) {
			ordered = append(ordered, resolved[idx])
		}
	}
	if len(ordered) == 0 {
		return resolved
	}
	return ordered
}

func routeHasTransit(r routesAPIRoute) bool {
	for _, leg := range r.Legs {
		for _, step := range leg.Steps {
			if strings.EqualFold(step.TravelMode, "TRANSIT") {
				return true
			}
		}
	}
	return false
}

func legsHaveTransit(legs []places.RouteLeg) bool {
	for _, leg := range legs {
		for _, step := range leg.Steps {
			if strings.EqualFold(step.TravelMode, "TRANSIT") {
				return true
			}
		}
	}
	return false
}

func pickBestRoute(routes []routesAPIRoute) routesAPIRoute {
	for _, r := range routes {
		if routeHasTransit(r) {
			return r
		}
	}
	return routes[0]
}

func transitDepartureTime() string {
	loc, err := time.LoadLocation("Europe/Istanbul")
	if err != nil {
		loc = time.UTC
	}
	return time.Now().In(loc).UTC().Format(time.RFC3339)
}

func (c *GoogleRoutesClient) computeRoutes(
	ctx context.Context,
	origin, dest routesWaypoint,
	mids []routesWaypoint,
	mode string,
	optimize bool,
	lang string,
	transitRoutingPref string,
) (*http.Response, []byte, error) {
	reqBody := routesRequest{
		Origin:                   origin,
		Destination:              dest,
		Intermediates:            mids,
		TravelMode:               mode,
		OptimizeWaypointOrder:    optimize,
		LanguageCode:             lang,
		ComputeAlternativeRoutes: false,
	}
	if mode == "TRANSIT" {
		reqBody.DepartureTime = transitDepartureTime()
		reqBody.RegionCode = "TR"
		reqBody.ComputeAlternativeRoutes = true
		pref := transitRoutingPref
		if pref == "" {
			pref = "LESS_WALKING"
		}
		reqBody.TransitPreferences = &routesTransitPrefs{
			RoutingPreference: pref,
		}
	}
	body, _ := json.Marshal(reqBody)

	httpReq, err := http.NewRequestWithContext(ctx, http.MethodPost, routesURL, bytes.NewReader(body))
	if err != nil {
		return nil, nil, domainErr.New(domainErr.ErrInternal, "failed to build routes request", err)
	}
	httpReq.GetBody = func() (io.ReadCloser, error) {
		return io.NopCloser(bytes.NewReader(body)), nil
	}
	httpReq.Header.Set("Content-Type", "application/json")
	httpReq.Header.Set("X-Goog-Api-Key", c.apiKey)
	httpReq.Header.Set("X-Goog-FieldMask", routesFieldMask)

	resp, raw, err := doGoogleRequest(ctx, c.http, httpReq)
	if err != nil {
		return nil, nil, domainErr.New(domainErr.ErrInternal, "routes request failed", err)
	}
	return resp, raw, nil
}

func waypointFromPlace(p places.Place) routesWaypoint {
	if p.PlaceID != "" {
		return routesWaypoint{PlaceID: p.PlaceID}
	}
	return latLngWaypoint(p.Location.Latitude, p.Location.Longitude)
}

func waypointForMode(p places.Place, mode string) routesWaypoint {
	if mode == "TRANSIT" && (p.Location.Latitude != 0 || p.Location.Longitude != 0) {
		return latLngWaypoint(p.Location.Latitude, p.Location.Longitude)
	}
	return waypointFromPlace(p)
}

func latLngWaypoint(lat, lng float64) routesWaypoint {
	return routesWaypoint{Location: &routesLocation{LatLng: &routesLatLng{
		Latitude: lat, Longitude: lng,
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
