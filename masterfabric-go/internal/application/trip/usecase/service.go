package usecase

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"github.com/leventkok/NavGo/internal/application/trip/dto"
	"github.com/leventkok/NavGo/internal/domain/places"
	"github.com/leventkok/NavGo/internal/domain/trip"
	domainErr "github.com/leventkok/NavGo/internal/shared/errors"
)

// Service implements trip application use cases shared by HTTP and MCP.
type Service struct {
	places      places.PlacesClient
	directions  places.DirectionsClient
	cache       places.PlaceCache
	itineraries trip.Repository
}

func NewService(
	placesClient places.PlacesClient,
	directions places.DirectionsClient,
	cache places.PlaceCache,
	itineraries trip.Repository,
) *Service {
	return &Service{
		places:      placesClient,
		directions:  directions,
		cache:       cache,
		itineraries: itineraries,
	}
}

func (s *Service) SearchPlaces(ctx context.Context, req dto.SearchPlacesRequest) (*places.SearchResponse, error) {
	if req.Query == "" {
		return nil, domainErr.New(domainErr.ErrValidation, "query is required", nil)
	}
	return s.places.Search(ctx, places.SearchRequest{
		Query:      req.Query,
		Area:       req.Area,
		Language:   req.Language,
		Lat:        req.Lat,
		Lng:        req.Lng,
		RadiusM:    req.RadiusM,
		MaxResults: req.MaxResults,
	})
}

func (s *Service) BuildRoute(ctx context.Context, req dto.BuildRouteRequest) (*places.BuildRouteResponse, error) {
	hasOrigin := req.OriginLat != 0 || req.OriginLng != 0
	minPlaces := 2
	if hasOrigin {
		minPlaces = 1
	}
	if len(req.PlaceIDs) < minPlaces {
		return nil, domainErr.New(domainErr.ErrValidation, "not enough place_ids for route", nil)
	}
	resolved, err := s.resolvePlaceIDs(ctx, req.PlaceIDs)
	if err != nil {
		return nil, err
	}
	return s.directions.BuildRoute(ctx, places.BuildRouteRequest{
		PlaceIDs:              req.PlaceIDs,
		TravelMode:            req.TravelMode,
		OptimizeWaypointOrder: req.OptimizeWaypointOrder,
		Language:              req.Language,
		OriginLat:             req.OriginLat,
		OriginLng:             req.OriginLng,
	}, resolved)
}

func (s *Service) SaveItinerary(ctx context.Context, userID uuid.UUID, req dto.SaveItineraryRequest) (*trip.Itinerary, error) {
	if userID == uuid.Nil {
		return nil, domainErr.New(domainErr.ErrUnauthorized, "user required", nil)
	}
	if req.Prompt == "" || len(req.Stops) == 0 {
		return nil, domainErr.New(domainErr.ErrValidation, "prompt and stops are required", nil)
	}

	ids := make([]string, 0, len(req.Stops))
	for _, st := range req.Stops {
		if st.PlaceID == "" {
			return nil, domainErr.New(domainErr.ErrValidation, "each stop requires place_id", nil)
		}
		ids = append(ids, st.PlaceID)
	}

	// Grounding: every place_id must exist in cache or upstream Places.
	if err := s.ensureGrounded(ctx, ids); err != nil {
		return nil, err
	}

	locale := req.Locale
	if locale == "" {
		locale = "tr"
	}
	stops := make([]trip.Stop, 0, len(req.Stops))
	for i, st := range req.Stops {
		order := st.Order
		if order == 0 {
			order = i + 1
		}
		// Prefer cache/upstream truth for lat/lng when available.
		if p, err := s.places.GetByPlaceID(ctx, st.PlaceID); err == nil && p != nil {
			stops = append(stops, trip.Stop{
				PlaceID:          p.PlaceID,
				DisplayName:      p.DisplayName,
				FormattedAddress: p.FormattedAddress,
				Location:         p.Location,
				Order:            order,
				Types:            p.Types,
				GoogleMapsURI:    p.GoogleMapsURI,
			})
			continue
		}
		stops = append(stops, trip.Stop{
			PlaceID:          st.PlaceID,
			DisplayName:      st.DisplayName,
			FormattedAddress: st.FormattedAddress,
			Location:         st.Location,
			Order:            order,
			Types:            st.Types,
			GoogleMapsURI:    st.GoogleMapsURI,
		})
	}

	it := &trip.Itinerary{
		UserID:           userID,
		OrganizationID:   req.OrganizationID,
		Prompt:           req.Prompt,
		Locale:           locale,
		Area:             req.Area,
		DurationLabel:    req.DurationLabel,
		Model:            req.Model,
		ClientMeta:       req.ClientMeta,
		Stops:            stops,
		OverviewPolyline: req.OverviewPolyline,
		GoogleMapsURL:    req.GoogleMapsURL,
		DistanceMeters:   req.DistanceMeters,
		DurationSeconds:  req.DurationSeconds,
	}
	if err := s.itineraries.Create(ctx, it); err != nil {
		return nil, err
	}
	return it, nil
}

func (s *Service) GetItinerary(ctx context.Context, id uuid.UUID) (*trip.Itinerary, error) {
	return s.itineraries.GetByID(ctx, id)
}

func (s *Service) ListItineraries(ctx context.Context, userID uuid.UUID, limit, offset int) ([]trip.Itinerary, error) {
	return s.itineraries.ListByUser(ctx, userID, limit, offset)
}

func (s *Service) PlanDay(ctx context.Context, req dto.PlanDayRequest) (*dto.PlanDayResponse, error) {
	maxStops := req.MaxStops
	if maxStops <= 0 {
		maxStops = 5
	}
	search, err := s.SearchPlaces(ctx, dto.SearchPlacesRequest{
		Query:      req.Prompt,
		Area:       req.Area,
		Language:   req.Locale,
		MaxResults: maxStops,
	})
	if err != nil {
		return nil, err
	}
	if len(search.Places) < 2 {
		return nil, domainErr.New(domainErr.ErrValidation, "not enough grounded places for a day plan", nil)
	}

	ids := make([]string, 0, len(search.Places))
	for _, p := range search.Places {
		ids = append(ids, p.PlaceID)
	}
	route, err := s.BuildRoute(ctx, dto.BuildRouteRequest{
		PlaceIDs:              ids,
		TravelMode:            req.TravelMode,
		OptimizeWaypointOrder: req.OptimizeWaypointOrder,
		Language:              req.Locale,
	})
	if err != nil {
		return nil, err
	}

	resp := &dto.PlanDayResponse{Search: search, Route: route}
	if req.Save {
		if req.UserID == uuid.Nil {
			return nil, domainErr.New(domainErr.ErrUnauthorized, "user required to save itinerary", nil)
		}
		stops := make([]dto.StopInput, 0, len(search.Places))
		order := route.WaypointOrder
		if len(order) != len(search.Places) {
			order = make([]int, len(search.Places))
			for i := range order {
				order[i] = i
			}
		}
		for i, idx := range order {
			p := search.Places[idx]
			stops = append(stops, dto.StopInput{
				PlaceID:          p.PlaceID,
				DisplayName:      p.DisplayName,
				FormattedAddress: p.FormattedAddress,
				Location:         p.Location,
				Order:            i + 1,
				Types:            p.Types,
				GoogleMapsURI:    p.GoogleMapsURI,
			})
		}
		it, err := s.SaveItinerary(ctx, req.UserID, dto.SaveItineraryRequest{
			Prompt:           req.Prompt,
			Locale:           req.Locale,
			Area:             req.Area,
			DurationLabel:    req.DurationLabel,
			Model:            req.Model,
			Stops:            stops,
			OverviewPolyline: route.OverviewPolyline,
			GoogleMapsURL:    route.GoogleMapsURL,
			DistanceMeters:   route.DistanceMeters,
			DurationSeconds:  route.DurationSeconds,
		})
		if err != nil {
			return nil, err
		}
		resp.Itinerary = it
	}
	return resp, nil
}

func (s *Service) resolvePlaceIDs(ctx context.Context, ids []string) ([]places.Place, error) {
	out := make([]places.Place, 0, len(ids))
	for _, id := range ids {
		p, err := s.places.GetByPlaceID(ctx, id)
		if err != nil || p == nil {
			return nil, domainErr.New(domainErr.ErrValidation, fmt.Sprintf("ungrounded place_id: %s", id), err)
		}
		out = append(out, *p)
	}
	return out, nil
}

func (s *Service) ensureGrounded(ctx context.Context, ids []string) error {
	// Prefer cache membership, then upstream lookup (which also warms cache).
	if s.cache != nil {
		found, err := s.cache.ExistsPlaceIDs(ctx, ids)
		if err != nil {
			return err
		}
		missing := make([]string, 0)
		for _, id := range ids {
			if !found[id] {
				missing = append(missing, id)
			}
		}
		for _, id := range missing {
			if _, err := s.places.GetByPlaceID(ctx, id); err != nil {
				return domainErr.New(domainErr.ErrValidation, fmt.Sprintf("ungrounded place_id: %s", id), err)
			}
		}
		return nil
	}
	_, err := s.resolvePlaceIDs(ctx, ids)
	return err
}
