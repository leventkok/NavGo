package trippg

import (
	"context"
	"encoding/json"
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/leventkok/NavGo/internal/domain/trip"
	domainErr "github.com/leventkok/NavGo/internal/shared/errors"
)

// ItineraryRepo implements trip.Repository.
type ItineraryRepo struct {
	db *pgxpool.Pool
}

func NewItineraryRepo(db *pgxpool.Pool) *ItineraryRepo {
	return &ItineraryRepo{db: db}
}

func (r *ItineraryRepo) Create(ctx context.Context, it *trip.Itinerary) error {
	if it.ID == uuid.Nil {
		it.ID = uuid.New()
	}
	now := time.Now().UTC()
	it.CreatedAt = now
	it.UpdatedAt = now

	stops, err := json.Marshal(it.Stops)
	if err != nil {
		return domainErr.New(domainErr.ErrValidation, "invalid stops", err)
	}
	meta, err := json.Marshal(it.ClientMeta)
	if err != nil || it.ClientMeta == nil {
		meta = []byte("{}")
	}

	_, err = r.db.Exec(ctx, `
		INSERT INTO itineraries (
			id, user_id, organization_id, prompt, locale, area, duration_label, model,
			client_meta, stops, overview_polyline, google_maps_url, distance_meters,
			duration_seconds, created_at, updated_at
		) VALUES (
			$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16
		)
	`,
		it.ID, it.UserID, it.OrganizationID, it.Prompt, it.Locale, it.Area, it.DurationLabel, it.Model,
		meta, stops, it.OverviewPolyline, it.GoogleMapsURL, it.DistanceMeters, it.DurationSeconds,
		it.CreatedAt, it.UpdatedAt,
	)
	if err != nil {
		return domainErr.New(domainErr.ErrInternal, "failed to create itinerary", err)
	}
	return nil
}

func (r *ItineraryRepo) GetByID(ctx context.Context, id uuid.UUID) (*trip.Itinerary, error) {
	var it trip.Itinerary
	var stops, meta []byte
	err := r.db.QueryRow(ctx, `
		SELECT id, user_id, organization_id, prompt, locale, area, duration_label, model,
		       client_meta, stops, overview_polyline, google_maps_url, distance_meters,
		       duration_seconds, created_at, updated_at
		FROM itineraries WHERE id = $1
	`, id).Scan(
		&it.ID, &it.UserID, &it.OrganizationID, &it.Prompt, &it.Locale, &it.Area, &it.DurationLabel, &it.Model,
		&meta, &stops, &it.OverviewPolyline, &it.GoogleMapsURL, &it.DistanceMeters, &it.DurationSeconds,
		&it.CreatedAt, &it.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, domainErr.New(domainErr.ErrNotFound, "itinerary not found", nil)
		}
		return nil, domainErr.New(domainErr.ErrInternal, "failed to get itinerary", err)
	}
	_ = json.Unmarshal(stops, &it.Stops)
	_ = json.Unmarshal(meta, &it.ClientMeta)
	return &it, nil
}

func (r *ItineraryRepo) ListByUser(ctx context.Context, userID uuid.UUID, limit, offset int) ([]trip.Itinerary, error) {
	if limit <= 0 {
		limit = 20
	}
	rows, err := r.db.Query(ctx, `
		SELECT id, user_id, organization_id, prompt, locale, area, duration_label, model,
		       client_meta, stops, overview_polyline, google_maps_url, distance_meters,
		       duration_seconds, created_at, updated_at
		FROM itineraries WHERE user_id = $1
		ORDER BY created_at DESC
		LIMIT $2 OFFSET $3
	`, userID, limit, offset)
	if err != nil {
		return nil, domainErr.New(domainErr.ErrInternal, "failed to list itineraries", err)
	}
	defer rows.Close()

	var out []trip.Itinerary
	for rows.Next() {
		var it trip.Itinerary
		var stops, meta []byte
		if err := rows.Scan(
			&it.ID, &it.UserID, &it.OrganizationID, &it.Prompt, &it.Locale, &it.Area, &it.DurationLabel, &it.Model,
			&meta, &stops, &it.OverviewPolyline, &it.GoogleMapsURL, &it.DistanceMeters, &it.DurationSeconds,
			&it.CreatedAt, &it.UpdatedAt,
		); err != nil {
			return nil, domainErr.New(domainErr.ErrInternal, "failed to scan itinerary", err)
		}
		_ = json.Unmarshal(stops, &it.Stops)
		_ = json.Unmarshal(meta, &it.ClientMeta)
		out = append(out, it)
	}
	return out, rows.Err()
}
