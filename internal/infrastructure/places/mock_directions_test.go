package placesinfra

import (
	"context"
	"testing"

	"github.com/leventkok/NavGo/internal/domain/places"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestMockDirections_BuildRoute(t *testing.T) {
	client := NewMockDirectionsClient()
	placesClient := NewMockPlacesClient()
	search, err := placesClient.Search(context.Background(), places.SearchRequest{
		Query: "kaleiçi", Area: "Antalya", MaxResults: 4,
	})
	require.NoError(t, err)
	require.GreaterOrEqual(t, len(search.Places), 2)

	resp, err := client.BuildRoute(context.Background(), places.BuildRouteRequest{
		PlaceIDs: []string{search.Places[0].PlaceID, search.Places[1].PlaceID},
		TravelMode: "WALK",
		OptimizeWaypointOrder: true,
	}, search.Places[:2])
	require.NoError(t, err)
	assert.Equal(t, "OK", resp.Status)
	assert.Equal(t, "mock", resp.Provider)
	assert.NotEmpty(t, resp.GoogleMapsURL)
	assert.Len(t, resp.Legs, 1)
}
