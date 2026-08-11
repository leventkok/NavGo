package placespg

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/leventkok/NavGo/internal/domain/places"
	domainErr "github.com/leventkok/NavGo/internal/shared/errors"
)

// CacheRepo implements places.PlaceCache with Postgres + pgvector.
type CacheRepo struct {
	db *pgxpool.Pool
}

func NewCacheRepo(db *pgxpool.Pool) *CacheRepo {
	return &CacheRepo{db: db}
}

func (r *CacheRepo) GetSearch(ctx context.Context, queryHash string) ([]places.Place, bool, error) {
	var placeIDs []string
	var expiresAt time.Time
	err := r.db.QueryRow(ctx,
		`SELECT place_ids, expires_at FROM place_search_cache WHERE query_hash = $1`, queryHash,
	).Scan(&placeIDs, &expiresAt)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, false, nil
		}
		return nil, false, domainErr.New(domainErr.ErrInternal, "failed to read search cache", err)
	}
	if time.Now().UTC().After(expiresAt) {
		return nil, false, nil
	}

	out := make([]places.Place, 0, len(placeIDs))
	for _, id := range placeIDs {
		cp, ok, err := r.GetPlace(ctx, id)
		if err != nil {
			return nil, false, err
		}
		if ok {
			out = append(out, cp.Place)
		}
	}
	if len(out) == 0 {
		return nil, false, nil
	}
	return out, true, nil
}

func (r *CacheRepo) PutSearch(ctx context.Context, queryHash, area string, list []places.Place, ttlSeconds int) error {
	ids := make([]string, 0, len(list))
	for _, p := range list {
		ids = append(ids, p.PlaceID)
	}
	expires := time.Now().UTC().Add(time.Duration(ttlSeconds) * time.Second)
	_, err := r.db.Exec(ctx, `
		INSERT INTO place_search_cache (query_hash, area, query_text, place_ids, created_at, expires_at)
		VALUES ($1, $2, $3, $4, NOW(), $5)
		ON CONFLICT (query_hash) DO UPDATE SET
			area = EXCLUDED.area,
			place_ids = EXCLUDED.place_ids,
			created_at = NOW(),
			expires_at = EXCLUDED.expires_at
	`, queryHash, area, "", ids, expires)
	if err != nil {
		return domainErr.New(domainErr.ErrInternal, "failed to write search cache", err)
	}
	return nil
}

func (r *CacheRepo) GetPlace(ctx context.Context, placeID string) (*places.CachedPlace, bool, error) {
	var cp places.CachedPlace
	var types []string
	var raw []byte
	var expiresAt time.Time
	err := r.db.QueryRow(ctx, `
		SELECT place_id, display_name, formatted_address, latitude, longitude, types,
		       rating, user_rating_count, google_maps_uri, business_status, raw_json,
		       fetched_at, expires_at
		FROM places_cache WHERE place_id = $1
	`, placeID).Scan(
		&cp.PlaceID, &cp.DisplayName, &cp.FormattedAddress, &cp.Location.Latitude, &cp.Location.Longitude, &types,
		&cp.Rating, &cp.UserRatingCount, &cp.GoogleMapsURI, &cp.BusinessStatus, &raw,
		&cp.FetchedAt, &expiresAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, false, nil
		}
		return nil, false, domainErr.New(domainErr.ErrInternal, "failed to read place cache", err)
	}
	if time.Now().UTC().After(expiresAt) {
		return nil, false, nil
	}
	cp.Types = types
	cp.RawJSON = raw
	cp.ExpiresAt = expiresAt
	return &cp, true, nil
}

func (r *CacheRepo) PutPlace(ctx context.Context, place places.CachedPlace) error {
	if place.ExpiresAt.IsZero() {
		place.ExpiresAt = time.Now().UTC().Add(6 * time.Hour)
	}
	if place.FetchedAt.IsZero() {
		place.FetchedAt = time.Now().UTC()
	}
	raw := place.RawJSON
	if len(raw) == 0 {
		raw, _ = json.Marshal(place.Place)
	}
	vec := vectorLiteral(place.Embedding)
	_, err := r.db.Exec(ctx, `
		INSERT INTO places_cache (
			place_id, display_name, formatted_address, latitude, longitude, types,
			rating, user_rating_count, google_maps_uri, business_status, raw_json,
			embedding, fetched_at, expires_at
		) VALUES (
			$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12::vector,$13,$14
		)
		ON CONFLICT (place_id) DO UPDATE SET
			display_name = EXCLUDED.display_name,
			formatted_address = EXCLUDED.formatted_address,
			latitude = EXCLUDED.latitude,
			longitude = EXCLUDED.longitude,
			types = EXCLUDED.types,
			rating = EXCLUDED.rating,
			user_rating_count = EXCLUDED.user_rating_count,
			google_maps_uri = EXCLUDED.google_maps_uri,
			business_status = EXCLUDED.business_status,
			raw_json = EXCLUDED.raw_json,
			embedding = EXCLUDED.embedding,
			fetched_at = EXCLUDED.fetched_at,
			expires_at = EXCLUDED.expires_at
	`,
		place.PlaceID, place.DisplayName, place.FormattedAddress, place.Location.Latitude, place.Location.Longitude, place.Types,
		place.Rating, place.UserRatingCount, place.GoogleMapsURI, place.BusinessStatus, raw,
		vec, place.FetchedAt, place.ExpiresAt,
	)
	if err != nil {
		return domainErr.New(domainErr.ErrInternal, "failed to write place cache", err)
	}
	return nil
}

func (r *CacheRepo) ExistsPlaceIDs(ctx context.Context, placeIDs []string) (map[string]bool, error) {
	out := make(map[string]bool, len(placeIDs))
	for _, id := range placeIDs {
		out[id] = false
	}
	if len(placeIDs) == 0 {
		return out, nil
	}
	rows, err := r.db.Query(ctx, `
		SELECT place_id FROM places_cache
		WHERE place_id = ANY($1) AND expires_at > NOW()
	`, placeIDs)
	if err != nil {
		return nil, domainErr.New(domainErr.ErrInternal, "failed to check place ids", err)
	}
	defer rows.Close()
	for rows.Next() {
		var id string
		if err := rows.Scan(&id); err != nil {
			return nil, domainErr.New(domainErr.ErrInternal, "failed to scan place id", err)
		}
		out[id] = true
	}
	return out, rows.Err()
}

func vectorLiteral(v []float32) string {
	if len(v) == 0 {
		v = make([]float32, 384)
	}
	parts := make([]string, len(v))
	for i, f := range v {
		parts[i] = fmt.Sprintf("%g", f)
	}
	return "[" + strings.Join(parts, ",") + "]"
}
