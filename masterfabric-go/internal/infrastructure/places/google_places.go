package placesinfra

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"

	"github.com/leventkok/NavGo/internal/domain/places"
	domainErr "github.com/leventkok/NavGo/internal/shared/errors"
)

const (
	placesSearchURL = "https://places.googleapis.com/v1/places:searchText"
	placesGetURL    = "https://places.googleapis.com/v1/places/"
	placesFieldMask = "places.id,places.displayName,places.formattedAddress,places.location,places.types,places.rating,places.userRatingCount,places.googleMapsUri,places.businessStatus"
	placeFieldMask  = "id,displayName,formattedAddress,location,types,rating,userRatingCount,googleMapsUri,businessStatus"
)

// GooglePlacesClient calls Places API (New).
type GooglePlacesClient struct {
	apiKey string
	http   *http.Client
}

func NewGooglePlacesClient(apiKey string) *GooglePlacesClient {
	return &GooglePlacesClient{apiKey: apiKey, http: newGoogleHTTPClient()}
}

type googleCircleCenter struct {
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
}

type googleCircle struct {
	Center googleCircleCenter `json:"center"`
	Radius float64            `json:"radius"`
}

type googleLocationBias struct {
	Circle *googleCircle `json:"circle,omitempty"`
}

type googleTextSearchRequest struct {
	TextQuery      string              `json:"textQuery"`
	LanguageCode   string              `json:"languageCode,omitempty"`
	MaxResultCount int                 `json:"maxResultCount,omitempty"`
	LocationBias   *googleLocationBias `json:"locationBias,omitempty"`
}

type googlePlacesSearchResponse struct {
	Places []googlePlace `json:"places"`
}

type googlePlace struct {
	ID               string   `json:"id"`
	Name             string   `json:"name"`
	FormattedAddress string   `json:"formattedAddress"`
	Types            []string `json:"types"`
	Rating           float64  `json:"rating"`
	UserRatingCount  int      `json:"userRatingCount"`
	GoogleMapsURI    string   `json:"googleMapsUri"`
	BusinessStatus   string   `json:"businessStatus"`
	DisplayName      *struct {
		Text string `json:"text"`
	} `json:"displayName"`
	Location *struct {
		Latitude  float64 `json:"latitude"`
		Longitude float64 `json:"longitude"`
	} `json:"location"`
}

func (c *GooglePlacesClient) Search(ctx context.Context, req places.SearchRequest) (*places.SearchResponse, error) {
	query := strings.TrimSpace(req.Query)
	if req.Area != "" {
		if query == "" {
			query = req.Area
		} else if !strings.Contains(strings.ToLower(query), strings.ToLower(req.Area)) {
			query = query + " " + req.Area
		}
	}
	if query == "" {
		return nil, domainErr.New(domainErr.ErrValidation, "query is required", nil)
	}
	lang := req.Language
	if lang == "" {
		lang = "tr"
	}
	max := req.MaxResults
	if max <= 0 {
		max = 8
	}
	if max > 20 {
		max = 20
	}

	searchReq := googleTextSearchRequest{
		TextQuery:      query,
		LanguageCode:   lang,
		MaxResultCount: max,
	}
	if req.Lat != 0 || req.Lng != 0 {
		radius := float64(req.RadiusM)
		if radius <= 0 {
			radius = 2500
		}
		searchReq.LocationBias = &googleLocationBias{
			Circle: &googleCircle{
				Center: googleCircleCenter{Latitude: req.Lat, Longitude: req.Lng},
				Radius: radius,
			},
		}
	}
	body, _ := json.Marshal(searchReq)
	httpReq, err := http.NewRequestWithContext(ctx, http.MethodPost, placesSearchURL, bytes.NewReader(body))
	if err != nil {
		return nil, domainErr.New(domainErr.ErrInternal, "failed to build places request", err)
	}
	httpReq.GetBody = func() (io.ReadCloser, error) {
		return io.NopCloser(bytes.NewReader(body)), nil
	}
	httpReq.Header.Set("Content-Type", "application/json")
	httpReq.Header.Set("X-Goog-Api-Key", c.apiKey)
	httpReq.Header.Set("X-Goog-FieldMask", placesFieldMask)

	resp, raw, err := doGoogleRequest(ctx, c.http, httpReq)
	if err != nil {
		return nil, domainErr.New(domainErr.ErrInternal, "places search failed", err)
	}
	if resp.StatusCode >= 300 {
		return nil, domainErr.New(domainErr.ErrBadRequest, fmt.Sprintf("places search http %d: %s", resp.StatusCode, truncate(string(raw), 300)), nil)
	}

	var parsed googlePlacesSearchResponse
	if err := json.Unmarshal(raw, &parsed); err != nil {
		return nil, domainErr.New(domainErr.ErrInternal, "places search decode failed", err)
	}
	out := make([]places.Place, 0, len(parsed.Places))
	for _, gp := range parsed.Places {
		if p := mapGooglePlace(gp); p != nil {
			out = append(out, *p)
		}
	}
	return &places.SearchResponse{
		Places:   out,
		CacheHit: false,
		Provider: "google",
	}, nil
}

func (c *GooglePlacesClient) GetByPlaceID(ctx context.Context, placeID string) (*places.Place, error) {
	id := strings.TrimPrefix(placeID, "places/")
	if id == "" {
		return nil, domainErr.New(domainErr.ErrValidation, "place_id required", nil)
	}
	u := placesGetURL + url.PathEscape(id)
	httpReq, err := http.NewRequestWithContext(ctx, http.MethodGet, u, nil)
	if err != nil {
		return nil, domainErr.New(domainErr.ErrInternal, "failed to build place get request", err)
	}
	httpReq.Header.Set("X-Goog-Api-Key", c.apiKey)
	httpReq.Header.Set("X-Goog-FieldMask", placeFieldMask)

	resp, raw, err := doGoogleRequest(ctx, c.http, httpReq)
	if err != nil {
		return nil, domainErr.New(domainErr.ErrInternal, "place get failed", err)
	}
	if resp.StatusCode >= 300 {
		return nil, domainErr.New(domainErr.ErrNotFound, fmt.Sprintf("place get http %d: %s", resp.StatusCode, truncate(string(raw), 300)), nil)
	}
	var gp googlePlace
	if err := json.Unmarshal(raw, &gp); err != nil {
		return nil, domainErr.New(domainErr.ErrInternal, "place get decode failed", err)
	}
	p := mapGooglePlace(gp)
	if p == nil {
		return nil, domainErr.New(domainErr.ErrNotFound, "place not found", nil)
	}
	return p, nil
}

func mapGooglePlace(gp googlePlace) *places.Place {
	placeID := strings.TrimPrefix(gp.ID, "places/")
	if placeID == "" {
		placeID = strings.TrimPrefix(gp.Name, "places/")
	}
	if placeID == "" {
		return nil
	}
	name := ""
	if gp.DisplayName != nil {
		name = gp.DisplayName.Text
	}
	loc := places.LatLng{}
	if gp.Location != nil {
		loc.Latitude = gp.Location.Latitude
		loc.Longitude = gp.Location.Longitude
	}
	return &places.Place{
		PlaceID:          placeID,
		DisplayName:      name,
		FormattedAddress: gp.FormattedAddress,
		Location:         loc,
		Types:            gp.Types,
		Rating:           gp.Rating,
		UserRatingCount:  gp.UserRatingCount,
		GoogleMapsURI:    gp.GoogleMapsURI,
		BusinessStatus:   gp.BusinessStatus,
	}
}

func truncate(s string, n int) string {
	if len(s) <= n {
		return s
	}
	return s[:n] + "..."
}
