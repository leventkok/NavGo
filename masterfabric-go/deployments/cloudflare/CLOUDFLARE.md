# NavGo LLM → Colab + Cloudflare Tunnel

Fine-tuned Gemma + LoRA on a Colab T4 GPU, published as HTTPS via Cloudflare. NavGo talks to it via the same `/v1/chat/completions` contract as Ollama.

```text
Mobil → NavGo API (Render) → https://….trycloudflare.com/v1 → Colab GPU
```

Server code lives in this folder (`server/`). Notebook: [`NavGo_Serve_Cloudflare.ipynb`](NavGo_Serve_Cloudflare.ipynb).

## 0) Prerequisites

1. Hugging Face: accept [Gemma](https://huggingface.co/google/gemma-2-2b-it) license; create a token.
2. Adapter on HF (default): `levonov/navgo-gemma-lora-v3` (or set `ADAPTER_ID` in the notebook).
3. Google Colab with **Runtime → Change runtime type → T4 GPU**.

## 1) Upload / open notebook

Option A — from this repo:

1. Open [Google Colab](https://colab.research.google.com/).
2. Upload `NavGo_Serve_Cloudflare.ipynb`.
3. Also upload the `server/` folder next to the notebook **or** clone this repo in the first cells (notebook clones/copies `server` into `/content/navgo-llm`).

Option B — clone NavGo in Colab (recommended; notebook does this):

```text
Config cell → set HF_TOKEN → run all cells
```

## 2) Config cell

| Variable | Meaning |
|----------|---------|
| `HF_TOKEN` | Required for gated Gemma + private/public adapter pull |
| `BASE_MODEL` | Default `google/gemma-2-2b-it` |
| `ADAPTER_ID` | Default `levonov/navgo-gemma-lora-v3` (HF repo id or local path) |
| `LLM_API_KEY` | Must match Render / `.env` `LLM_API_KEY`; empty → auto-generate |
| `CLOUDFLARE_TUNNEL_TOKEN` | Optional named tunnel; empty → rotating `trycloudflare.com` URL |
| `LLM_PUBLIC_URL` | Required if using named tunnel (stable HTTPS origin, no trailing slash) |

## 3) Run

1. Run cells **1 → last** in order.
2. Keep the **last cell running** (blocks). Closing the tab kills the tunnel.
3. Copy the printed block into Render env and/or local `.env`:

```env
LLM_BASE_URL=https://xxxx.trycloudflare.com/v1
LLM_MODEL=navgo-gemma
LLM_API_KEY=...
SERVER_WRITE_TIMEOUT_SECONDS=300
```

## 4) Smoke test

```bash
curl -s https://xxxx.trycloudflare.com/health

curl -s https://xxxx.trycloudflare.com/v1/chat/completions \
  -H "Authorization: Bearer YOUR_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"navgo-gemma","messages":[{"role":"user","content":"hi"}],"max_tokens":32}'
```

Without a key, chat should return **401**.

## 5) Wire to Render

See [docs/RENDER.md](../../docs/RENDER.md). After each Colab restart, quick-tunnel URL changes — update `LLM_BASE_URL` on the Web Service.

## Named tunnel (stable domain)

Example for NavGo: `llm.nomagent.com`.

1. Domain on Cloudflare (nameservers at registrar → Cloudflare).
2. Zero Trust → Networks → Tunnels → Create → copy token.
3. Public Hostname: subdomain `llm`, domain `nomagent.com`, type HTTP, URL `localhost:8000`.
4. Colab config:

```python
CLOUDFLARE_TUNNEL_TOKEN = "eyJ..."
LLM_PUBLIC_URL = "https://llm.nomagent.com"
```

5. NavGo / Render env (does not change on Colab restart):

```env
LLM_BASE_URL=https://llm.nomagent.com/v1
LLM_MODEL=navgo-gemma
LLM_API_KEY=...
SERVER_WRITE_TIMEOUT_SECONDS=300
```

## Notes

- Quick tunnel URLs (`*.trycloudflare.com`) are **ephemeral**. Prefer named tunnel + custom domain.
- Colab idle disconnect stops the model; re-run the notebook (same token → same hostname).
- Local Ollama remains optional for offline dev (`LLM_BASE_URL=http://127.0.0.1:11434/v1`).
