# Crypto & secrets

Secrets live in environment variables / host secret managers. Never commit `.env`. Rotate `JWT_SECRET`, Maps, and LLM keys on suspected exposure. Prefer TLS for all external links (`DB_SSLMODE=require` in production).
