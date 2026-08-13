# NavGo LLM — kullanım + geniş fine-tune yolu

## 1) HF’ye giden LoRA’yı indirmeden kullanabilir miyim?

**Kısa cevap:** Adapter klasörü tek başına “URL’ye istek at” modeli değil.  
Base Gemma + LoRA’yı bir yerde **yükleyip** OpenAI-compatible API açan bir servis gerekir.

| Yol | Lokal indirme? | NavGo `.env` | Not |
|-----|----------------|--------------|-----|
| **Colab + Cloudflare Tunnel** | Hayır (HF’den çeker) | `https://….trycloudflare.com/v1` | Önerilen canlı yol — [`../cloudflare/CLOUDFLARE.md`](../cloudflare/CLOUDFLARE.md) |
| **Ollama (PC)** | Evet (model iner) | `LLM_BASE_URL=http://127.0.0.1:11434/v1` | Lokal test |
| **HF Inference Endpoint** | Hayır (bulutta) | Endpoint’in `/v1` URL’i | Kart / ücret; merged veya PEFT-aware image |
| **HF Spaces ZeroGPU** | Hayır | Gradio API (Go `/v1` ile uyumsuz) | Demo UI; NavGo için proxy gerekir |
| **Kendi GPU sunucu** (MLC/vLLM/Ollama) | Sunucuda iner, telefonda yok | `https://.../v1` | InferReview tarzı |
| **Sadece HF model sayfası** | — | Çalışmaz | Repo ≠ chat API |

HF’de şu an genelde: `.../navgo-gemma-lora-v1` = **LoRA ağırlıkları**.  
Chat için ya:

1. Colab’da **merge** edip `.../navgo-gemma-merged-v1` yükle → Inference Endpoint / vLLM, veya  
2. Lokal Ollama’ya base + adapter / GGUF al.

NavGo zaten şunu bekliyor:

```env
LLM_BASE_URL=https://SENIN-ENDPOINT/v1
LLM_MODEL=...
LLM_API_KEY=...   # endpoint istiyorsa
```

`POST /api/v1/llm/parse-intent` → Go → `LLM_BASE_URL/chat/completions`.

---

## 2) Geniş fine-tune path (binlerce kullanıcı / dünya)

### Faz A — Pipeline doğrulandı (sen buradasın)
- [x] `train_v1.jsonl` (~100 satır)
- [x] Colab QLoRA
- [x] Adapter HF’de
- [ ] Merge → HF (opsiyonel ama API host için iyi)
- [ ] NavGo’da gerçek inference (Ollama veya bulut endpoint)

### Faz B — Veri ölçeği (asıl kalite)
Hedef dosya: `train_v2.jsonl` (intent + pick_stops karışık)

| Sürüm | Satır | İçerik |
|-------|------:|--------|
| v1 | ~100 | Demo TR/EN |
| v2 | 1–2k | +20 şehir, TR/EN/ES/DE/FR, edge case |
| v3 | 5–10k+ | Gerçek kullanım logları (anonim) + sentetik |

Kurallar (değişmez):
- System metni = `service.go` ile aynı
- Assistant = sadece JSON
- `place_id` / lat / lng yok
- Prompt dili = `duration_label` / `query` dili

Üretim:
1. Başka AI ile çoğaltma promptu (önceki mesajdaki)
2. İyi Plan oturumlarını JSONL’e çevir (izinli log)
3. `train_v1` + yeni → `train_v2.jsonl` birleştir

Klasör düzeni:

```text
deployments/peft-adapters/
  sample_train_intent.jsonl
  sample_train_pick_stops.jsonl
  train_v1.jsonl          ← mevcut
  train_v2.jsonl          ← sonraki
  COLAB-GUIDE.md
  PATH.md                 ← bu dosya
```

### Faz C — Retrain (Colab, aynı recipe)
1. `train_v2.jsonl` upload  
2. Aynı QLoRA ayarları (`r=16`, 3 epoch veya 2)  
3. HF’ye yeni repo: `navgo-gemma-lora-v2` (v1’i silme — A/B)  
4. Merge → `navgo-gemma-merged-v2` (endpoint kullanacaksan)

### Faz D — Serve (kullanıcıya giden yol)
```
Mobil → NavGo API (Render) → LLM_BASE_URL (OpenAI-compatible)
                         ├─ dev:  Ollama localhost
                         └─ prod: Colab + Cloudflare (veya HF Endpoint / GPU host)
```

Ölçek checklist:
- [ ] JSON parse fail % metriği
- [ ] Boş Places / kötü rota feedback
- [ ] Dil/locale → Places `language`
- [ ] LLM down → PreferenceQueryBuilder fallback (zaten var)
- [ ] Rate limit + cache

### Faz E — Model büyütme (gerekirse)
2B yetmezse: aynı veri ile `gemma-2-9b-it` QLoRA (daha pahalı Colab/GPU).  
Fine-tune coğrafya ezberi değil; **JSON + NavGo stili** öğretir. Dünya kapsamı = Places grounding + çeşitli veri.

---

## 3) Şimdi senin net sonraki 3 adım

1. **Serve:** Colab notebook [`../cloudflare/NavGo_Serve_Cloudflare.ipynb`](../cloudflare/NavGo_Serve_Cloudflare.ipynb) → Cloudflare URL’yi Render `LLM_*` env’e yapıştır  
2. **API/DB:** [`../../docs/RENDER.md`](../../docs/RENDER.md) — Render Web Service + Postgres  
3. **Dev:** PC’de Ollama + `gemma2:2b` → `LLM_BASE_URL=http://127.0.0.1:11434/v1`

İndirmeden HTTP ile kullanmak = Colab+Cloudflare (veya merged + HF Endpoint); sadece LoRA repo sayfası yetmez.
