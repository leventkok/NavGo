-- +goose Up
CREATE TABLE IF NOT EXISTS auth_handshakes (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id       UUID NOT NULL,
    channel_id      UUID NOT NULL,
    barrier_hash    TEXT NOT NULL,
    barrier_hint    TEXT NOT NULL,
    bound_user_id   UUID,
    expires_at      TIMESTAMPTZ NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    bound_at        TIMESTAMPTZ
);

CREATE INDEX idx_auth_handshakes_device ON auth_handshakes(device_id);
CREATE INDEX idx_auth_handshakes_channel ON auth_handshakes(channel_id);
CREATE INDEX idx_auth_handshakes_expires ON auth_handshakes(expires_at);

CREATE TABLE IF NOT EXISTS security_scans (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID,
    user_id         UUID,
    source          VARCHAR(64) NOT NULL DEFAULT 'mcp',
    score_grade     VARCHAR(8),
    score_value     INT,
    report          JSONB NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_security_scans_created ON security_scans(created_at DESC);
CREATE INDEX idx_security_scans_org ON security_scans(organization_id);

-- +goose Down
DROP TABLE IF EXISTS security_scans;
DROP TABLE IF EXISTS auth_handshakes;
