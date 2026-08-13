# NavGo v3 — son fine-tune turu

v2 (~178) üzerine yeni batch ekle → `train_v3.jsonl` → Colab’da base’den QLoRA → HF `navgo-gemma-lora-v3`.

## 1) Yeni veri (başka AI — tek prompt)

Aşağıyı yapıştır; çıktıyı kaydet: `train_v3_batch.jsonl`

```text
You generate fine-tuning data for NavGo (travel day planner).

Output ONLY JSONL. One JSON object per line. No markdown, no commentary, no numbering.

Each line MUST be:
{"messages":[{"role":"system","content":"..."},{"role":"user","content":"..."},{"role":"assistant","content":"..."}]}

Generate TWO task types in ONE file, mixed randomly (~50/50):

TASK A — parse intent
SYSTEM (verbatim):
You are the NavGo travel assistant. The user may write in any language; follow their language for area/query/duration_label text. Return ONLY valid JSON, no other text. Schema: {"area":"string","query":"string","duration_label":"string","max_stops":number}. Do NOT invent place_id, lat, or lng. area is a district/city (e.g. Kadıköy Istanbul). query is a search phrase in the user's language. max_stops is 3-6.

USER: Preferences block (optional) + Prompt in TR/EN/other.
ASSISTANT: only {"area","query","duration_label","max_stops"} — same language as prompt; no place_id.

TASK B — pick stops
SYSTEM (verbatim):
From the numbered place list, pick stop indices for a day plan. The user prompt may be in any language; use it only to choose relevant places. Return ONLY JSON: {"indices":[number,...]}. Do not use numbers absent from the list. Do not invent place_id.

USER: Prompt / Max / Places: 0. Name — Address ...
ASSISTANT: only {"indices":[...]} valid indices.

DIVERSITY (important for v3):
- Cities worldwide: Europe, Asia, Americas, Middle East, Africa
- Edge cases: family (no nightlife), rainy day, 2-hour window, jetlag, food allergy soft bias, first-time tourist, local resident
- Mix TR/EN ~50/50; a few DE/ES/FR ok
- Do not copy train_v1/v2 prompts; make new ones

Generate 120 lines total (~60 A + ~60 B, shuffled).
```

## 2) Birleştir (PC)

```powershell
cd c:\Users\leven\projects\NavGo\masterfabric-go\deployments\peft-adapters
Get-Content train_v2.jsonl, train_v3_batch.jsonl |
  Set-Content -Encoding utf8 train_v3.jsonl
(Get-Content train_v3.jsonl | Measure-Object -Line).Lines
```

Beklenen: ~300 satır. Dosyayı koyunca Cursor’da “birleştir” demen yeterli.

## 3) Colab (sıfırdan, base Gemma)

1. Runtime → Restart session  
2. Upload `train_v3.jsonl`  
3. pip + login + model hücresi (v2 ile aynı, `float16`)  
4. Veri:

```python
ds = load_dataset("json", data_files="train_v3.jsonl", split="train")
print(len(ds))
```

5. Eğitim hücresi — `output_dir` / save: `./navgo-lora-v3`  
   (`fp16=False`, `bf16=False`, `remove_columns` → sadece `text`)

## 4) HF

```python
REPO = "SENIN_HF_USER/navgo-gemma-lora-v3"
api.create_repo(REPO, exist_ok=True)
api.upload_folder(folder_path="./navgo-lora-v3", repo_id=REPO, repo_type="model")
```

## 5) Sonra test

Sunucu/Ollama hazır olunca v3’ü bağlarız. Eğitim bitmeden test şart değil.
