-- +goose Up
CREATE TABLE IF NOT EXISTS itineraries (
    id                 UUID PRIMARY KEY,
    user_id            UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    organization_id    UUID REFERENCES organizations(id) ON DELETE SET NULL,
    prompt             TEXT NOT NULL,
    locale             TEXT NOT NULL DEFAULT 'tr',
    area               TEXT NOT NULL DEFAULT '',
    duration_label     TEXT NOT NULL DEFAULT '',
    model              TEXT NOT NULL DEFAULT '',
    client_meta        JSONB NOT NULL DEFAULT '{}',
    stops              JSONB NOT NULL DEFAULT '[]',
    overview_polyline  TEXT NOT NULL DEFAULT '',
    google_maps_url    TEXT NOT NULL DEFAULT '',
    distance_meters    BIGINT NOT NULL DEFAULT 0,
    duration_seconds   BIGINT NOT NULL DEFAULT 0,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_itineraries_user_id ON itineraries (user_id);
CREATE INDEX IF NOT EXISTS idx_itineraries_created_at ON itineraries (created_at DESC);

-- +goose Down
DROP TABLE IF EXISTS itineraries;
