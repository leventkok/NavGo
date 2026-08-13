# NavGo fine-tune veri şablonu

InferReview’daki gibi: **Colab’da QLoRA**, veri = production prompt ile aynı.

Kullanıcı **her dilde** yazabilir; model prompt diline göre `area` / `query` / `duration_label` üretir. JSON anahtarları her zaman İngilizce kalır.

## İki görev

| Dosya | Ne öğretir | Assistant çıktısı |
|-------|------------|-------------------|
| `sample_train_intent.jsonl` | Prompt → arama intent | `area`, `query`, `duration_label`, `max_stops` |
| `sample_train_pick_stops.jsonl` | Listeden durak seç | `indices` |

`place_id` / lat / lng **asla** uydurma.

## Satır formatı (chat)

```json
{
  "messages": [
    { "role": "system", "content": "..." },
    { "role": "user", "content": "..." },
    { "role": "assistant", "content": "{...JSON only...}" }
  ]
}
```

## Nasıl büyütürsün?

1. Bu sample’ları kopyala → `train_v1.jsonl`
2. TR + EN (+ başka diller) prompt ekle (hedef ~200+)
3. System metnini **koddakiyle aynı tut** (`internal/application/llm/usecase/service.go`)
4. Colab: InferReview gibi — `google/gemma-2-2b-it`, QLoRA, 2–3 epoch

## Colab’da kısa akış

1. JSONL yükle  
2. QLoRA train  
3. Adapter’ı HF’ye yükle (`navgo-gemma-lora-v3`)  
4. **Serve:** Colab + Cloudflare (önerilen) → [`../cloudflare/CLOUDFLARE.md`](../cloudflare/CLOUDFLARE.md)  
   veya lokal Ollama / merge  
5. NavGo / Render: `LLM_BASE_URL` + `LLM_MODEL` (+ `LLM_API_KEY`)
