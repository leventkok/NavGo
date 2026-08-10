package places

import "context"

// PlacesClient searches and resolves grounded places (Google shape).
type PlacesClient interface {
	Search(ctx context.Context, req SearchRequest) (*SearchResponse, error)
	GetByPlaceID(ctx context.Context, placeID string) (*Place, error)
}

// DirectionsClient builds routes between grounded place IDs.
type DirectionsClient interface {
	BuildRoute(ctx context.Context, req BuildRouteRequest, places []Place) (*BuildRouteResponse, error)
}

// PlaceCache stores Places responses to control API cost.
type PlaceCache interface {
	GetSearch(ctx context.Context, queryHash string) ([]Place, bool, error)
	PutSearch(ctx context.Context, queryHash string, area string, places []Place, ttlSeconds int) error
	GetPlace(ctx context.Context, placeID string) (*CachedPlace, bool, error)
	PutPlace(ctx context.Context, place CachedPlace) error
	ExistsPlaceIDs(ctx context.Context, placeIDs []string) (map[string]bool, error)
}
