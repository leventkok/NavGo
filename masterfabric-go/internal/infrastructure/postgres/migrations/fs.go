package migrations

import "embed"

// FS holds goose SQL migration files for startup / CLI apply.
//
//go:embed *.sql
var FS embed.FS
