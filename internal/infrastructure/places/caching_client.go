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
	inner places.PlacesClient
	cache places.PlaceCache
	ttl   time.Duration
}

func NewCachingPlacesClient(inner places.PlacesClient, cache places.PlaceCache) *CachingPlacesClient {
	return &CachingPlacesClient{inner: inner, cache: cache, ttl: defaultSearchTTL}
}

func (c *CachingPlacesClient) Search(ctx context.Context, req places.SearchRequest) (*places.SearchResponse, error) {
	hash := searchHash(req)
	if cached, ok, err := c.cache.GetSearch(ctx, hash); err == nil && ok {
		return &places.SearchResponse{
			Places:   cached,
			CacheHit: true,
			Provider: "cache",
		}, nil
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
	return resp, nil
}

func (c *CachingPlacesClient) GetByPlaceID(ctx context.Context, placeID string) (*places.Place, error) {
	if cp, ok, err := c.cache.GetPlace(ctx, placeID); err == nil && ok {
		p := cp.Place
		return &p, nil
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

func searchHash(req places.SearchRequest) string {
	raw := fmt.Sprintf("%s|%s|%s|%d|%.5f|%.5f|%d",
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
