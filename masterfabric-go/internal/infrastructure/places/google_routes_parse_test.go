package placesinfra

import (
	"encoding/json"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestUnmarshalTransitVehicleLocalizedName(t *testing.T) {
	raw := []byte(`{
		"routes": [{
			"distanceMeters": 12000,
			"duration": "1920s",
			"legs": [{
				"distanceMeters": 12000,
				"duration": "1920s",
				"steps": [
					{
						"travelMode": "WALK",
						"distanceMeters": 600,
						"navigationInstruction": {"instructions": "Kuzey yönünde ilerleyin"}
					},
					{
						"travelMode": "TRANSIT",
						"transitDetails": {
							"headsign": "Varsak",
							"stopCount": 8,
							"transitLine": {
								"name": "Kepez-Varsak",
								"nameShort": "MC68",
								"vehicle": {"name": {"text": "Otobüs"}, "type": "BUS"}
							},
							"stopDetails": {
								"departureStop": {
									"name": "Şehit Üsteğmen Gökhan Korkut Cd-9",
									"location": {"latLng": {"latitude": 36.90, "longitude": 30.71}}
								},
								"arrivalStop": {
									"name": "Kılıçarslan",
									"location": {"latLng": {"latitude": 36.888, "longitude": 30.679}}
								}
							}
						}
					}
				]
			}]
		}]
	}`)

	var parsed routesResponse
	require.NoError(t, json.Unmarshal(raw, &parsed))
	require.Len(t, parsed.Routes, 1)
	assert.True(t, routeHasTransit(parsed.Routes[0]))

	steps := parseRouteSteps(parsed.Routes[0].Legs[0].Steps)
	require.Len(t, steps, 2)
	assert.Equal(t, "WALK", steps[0].TravelMode)
	assert.Equal(t, "MC68", steps[1].TransitLine)
	assert.Equal(t, "Otobüs", steps[1].TransitVehicle)
	assert.Equal(t, "Şehit Üsteğmen Gökhan Korkut Cd-9", steps[1].DepartureStop)
	assert.Equal(t, "Kılıçarslan", steps[1].ArrivalStop)
	assert.Equal(t, "Varsak", steps[1].Headsign)
}
