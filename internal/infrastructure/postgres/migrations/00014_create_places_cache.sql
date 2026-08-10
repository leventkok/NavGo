-- +goose Up
CREATE TABLE IF NOT EXISTS places_cache (
    place_id           TEXT PRIMARY KEY,
    display_name       TEXT NOT NULL,
    formatted_address  TEXT NOT NULL DEFAULT '',
    latitude           DOUBLE PRECISION NOT NULL,
    longitude          DOUBLE PRECISION NOT NULL,
    types              TEXT[] NOT NULL DEFAULT '{}',
    rating             DOUBLE PRECISION NOT NULL DEFAULT 0,
    user_rating_count  INTEGER NOT NULL DEFAULT 0,
    google_maps_uri    TEXT NOT NULL DEFAULT '',
    business_status    TEXT NOT NULL DEFAULT '',
    raw_json           JSONB NOT NULL DEFAULT '{}',
    embedding          vector(384),
    fetched_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at         TIMESTAMPTZ NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_places_cache_expires_at ON places_cache (expires_at);
-- ANN index added later once the cache has rows (ivfflat needs training data).

CREATE TABLE IF NOT EXISTS place_search_cache (
    query_hash   TEXT PRIMARY KEY,
    area         TEXT NOT NULL DEFAULT '',
    query_text   TEXT NOT NULL DEFAULT '',
    place_ids    TEXT[] NOT NULL DEFAULT '{}',
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at   TIMESTAMPTZ NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_place_search_cache_expires_at ON place_search_cache (expires_at);

-- +goose Down
DROP TABLE IF EXISTS place_search_cache;
DROP TABLE IF EXISTS places_cache;
