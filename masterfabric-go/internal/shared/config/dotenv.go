package config

import (
	"os"
	"path/filepath"

	"github.com/joho/godotenv"
)

// loadDotEnv loads masterfabric-go/.env (and cwd .env) into the process env.
// Existing OS env vars win — godotenv does not override them.
func loadDotEnv() {
	candidates := []string{
		".env",
		filepath.Join("masterfabric-go", ".env"),
	}

	// When binary is run from repo root or from masterfabric-go/.
	if exe, err := os.Executable(); err == nil {
		dir := filepath.Dir(exe)
		candidates = append(candidates,
			filepath.Join(dir, ".env"),
			filepath.Join(dir, "..", ".env"),
			filepath.Join(dir, "..", "masterfabric-go", ".env"),
		)
	}

	seen := map[string]struct{}{}
	for _, p := range candidates {
		abs, err := filepath.Abs(p)
		if err != nil {
			continue
		}
		if _, ok := seen[abs]; ok {
			continue
		}
		seen[abs] = struct{}{}
		_ = godotenv.Load(abs)
	}
}
