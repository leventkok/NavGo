-- +goose Up
CREATE TABLE IF NOT EXISTS auth_magic_links (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email           TEXT NOT NULL,
    token_hash      TEXT NOT NULL,
    handshake_id    UUID NOT NULL REFERENCES auth_handshakes(id),
    expires_at      TIMESTAMPTZ NOT NULL,
    used_at         TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_auth_magic_links_email ON auth_magic_links(email);
CREATE INDEX idx_auth_magic_links_hash ON auth_magic_links(token_hash);

-- +goose Down
DROP TABLE IF EXISTS auth_magic_links;
