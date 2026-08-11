package placesinfra

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"github.com/leventkok/NavGo/internal/domain/places"
)

const defaultSearchTTL = 6 * time.Hour

// CachingPlacesClient wraps a PlacesClient with PlaceCache (pgvector-backed).
type CachingPlacesClient struct {
	inner    places.PlacesClient
	cache    places.PlaceCache
	ttl      time.Duration
	provider string // "mock" | "google" — included in cache keys
}

func NewCachingPlacesClient(inner places.PlacesClient, cache places.PlaceCache, provider string) *CachingPlacesClient {
	if provider == "" {
		provider = "unknown"
	}
	return &CachingPlacesClient{inner: inner, cache: cache, ttl: defaultSearchTTL, provider: provider}
}

func (c *CachingPlacesClient) Search(ctx context.Context, req places.SearchRequest) (*places.SearchResponse, error) {
	hash := searchHash(c.provider, req)
	if cached, ok, err := c.cache.GetSearch(ctx, hash); err == nil && ok {
		if c.usableCachedPlaces(cached) {
			return &places.SearchResponse{
				Places:   cached,
				CacheHit: true,
				Provider: c.provider + "+cache",
			}, nil
		}
	}

	resp, err := c.inner.Search(ctx, req)
	if err != nil {
		return nil, err
	}

	for _, p := range resp.Places {
		_ = c.cache.PutPlace(ctx, places.CachedPlace{
			Place:     p,
			RawJSON:   mustJSON(p),
			Embedding: fakeEmbedding(p.PlaceID),
			FetchedAt: time.Now().UTC(),
			ExpiresAt: time.Now().UTC().Add(c.ttl),
		})
	}
	_ = c.cache.PutSearch(ctx, hash, req.Area, resp.Places, int(c.ttl.Seconds()))
	resp.CacheHit = false
	if resp.Provider == "" {
		resp.Provider = c.provider
	}
	return resp, nil
}

func (c *CachingPlacesClient) GetByPlaceID(ctx context.Context, placeID string) (*places.Place, error) {
	// Never serve fixture IDs from cache when wired to Google Routes.
	if c.provider == "google" && isFixturePlaceID(placeID) {
		return c.inner.GetByPlaceID(ctx, placeID)
	}
	if cp, ok, err := c.cache.GetPlace(ctx, placeID); err == nil && ok {
		if c.provider != "google" || !isFixturePlaceID(cp.PlaceID) {
			p := cp.Place
			return &p, nil
		}
	}
	p, err := c.inner.GetByPlaceID(ctx, placeID)
	if err != nil {
		return nil, err
	}
	_ = c.cache.PutPlace(ctx, places.CachedPlace{
		Place:     *p,
		RawJSON:   mustJSON(p),
		Embedding: fakeEmbedding(p.PlaceID),
		FetchedAt: time.Now().UTC(),
		ExpiresAt: time.Now().UTC().Add(c.ttl),
	})
	return p, nil
}

func (c *CachingPlacesClient) usableCachedPlaces(list []places.Place) bool {
	if len(list) == 0 {
		return false
	}
	if c.provider != "google" {
		return true
	}
	for _, p := range list {
		if isFixturePlaceID(p.PlaceID) {
			return false
		}
	}
	return true
}

// Fixture IDs from MockPlacesClient (e.g. ChIJkaleici_hadrian_gate).
func isFixturePlaceID(id string) bool {
	id = strings.ToLower(strings.TrimSpace(id))
	return strings.Contains(id, "kaleici") ||
		strings.HasPrefix(id, "chijkaleici_") ||
		strings.Contains(id, "_hadrian_") ||
		strings.Contains(id, "_antalya_")
}

func searchHash(provider string, req places.SearchRequest) string {
	raw := fmt.Sprintf("%s|%s|%s|%s|%d|%.5f|%.5f|%d",
		provider,
		strings.ToLower(strings.TrimSpace(req.Query)),
		strings.ToLower(strings.TrimSpace(req.Area)),
		strings.ToLower(strings.TrimSpace(req.Language)),
		req.RadiusM, req.Lat, req.Lng, req.MaxResults,
	)
	sum := sha256.Sum256([]byte(raw))
	return hex.EncodeToString(sum[:])
}

func mustJSON(v any) []byte {
	b, _ := json.Marshal(v)
	return b
}

// fakeEmbedding produces a deterministic 384-d vector for mock/cache wiring.
// Replaced by a real embedder when Google/semantic search is enabled.
func fakeEmbedding(placeID string) []float32 {
	out := make([]float32, 384)
	sum := sha256.Sum256([]byte(placeID))
	for i := range out {
		out[i] = float32(sum[i%len(sum)]) / 255.0
	}
	return out
}
