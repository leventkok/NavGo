# NavGo — Colab QLoRA fine-tune (adım adım)

InferReview ile aynı mantık. Eğitim **Colab’da**; NavGo’da model **lokal Ollama** ile çalışır.

## BFloat16 hatası alıyorsan (şimdi)

1. Menü: **Runtime → Restart session** (Disconnect and delete runtime DEĞİL, Restart yeterli; GPU sıfırlanır)
2. Sol Files’tan `train_v1.jsonl` **yoksa tekrar Upload** et
3. Aşağıdaki hücreleri **1 → 2 → 3 → 4 → 5** sırayla, hiç atlamadan çalıştır
4. Eğitimde `fp16=False` ve `bf16=False` olmalı (GradScaler kapalı — T4 için en güvenlisi)

---

## 0) Hazırlık (PC’de, 10 dk)

1. Klasör: `masterfabric-go/deployments/peft-adapters/`
2. İki sample’ı birleştir:

```bash
# PowerShell (masterfabric-go/deployments/peft-adapters içinde)
Get-Content sample_train_intent.jsonl, sample_train_pick_stops.jsonl |
  Set-Content train_v1.jsonl
```

3. `train_v1.jsonl` içine **daha fazla satır ekle** (hedef 200+).
   - Format: `system` + `user` + `assistant` (sadece JSON)
   - System metni = `service.go` içindekiyle **aynı**
   - TR + EN karışık olsun
   - `place_id` uydurma

4. HuggingFace hesabı + **Write** token  
   - Gemma erişimini kabul et: `google/gemma-2-2b-it`

---

## 1) Colab aç

1. https://colab.research.google.com → Yeni notebook  
2. **Runtime → Change runtime type → T4 GPU**  
3. `train_v1.jsonl` dosyasını Colab’a yükle (sol panel Files → Upload)

---

## 2) Kurulum (Colab hücresi)

```python
!pip install -q transformers peft trl bitsandbytes accelerate datasets huggingface_hub
```

```python
from huggingface_hub import login
login()  # Write token yapıştır
```

---

## 3) Veriyi yükle

```python
from datasets import load_dataset

ds = load_dataset("json", data_files="train_v1.jsonl", split="train")
print(len(ds), ds[0])
```

---

## 4) Model + QLoRA

```python
import torch
from transformers import AutoModelForCausalLM, AutoTokenizer, BitsAndBytesConfig
from peft import LoraConfig, get_peft_model, prepare_model_for_kbit_training

BASE = "google/gemma-2-2b-it"

bnb = BitsAndBytesConfig(
    load_in_4bit=True,
    bnb_4bit_quant_type="nf4",
    # T4: use float16 (bfloat16 + fp16 GradScaler → NotImplementedError)
    bnb_4bit_compute_dtype=torch.float16,
)

tok = AutoTokenizer.from_pretrained(BASE)
tok.pad_token = tok.eos_token

model = AutoModelForCausalLM.from_pretrained(
    BASE, quantization_config=bnb, device_map="auto"
)
model = prepare_model_for_kbit_training(model)

lora = LoraConfig(
    r=16,
    lora_alpha=32,
    lora_dropout=0.05,
    bias="none",
    task_type="CAUSAL_LM",
    target_modules=[
        "q_proj", "k_proj", "v_proj", "o_proj",
        "gate_proj", "up_proj", "down_proj",
    ],
)
model = get_peft_model(model, lora)
model.print_trainable_parameters()
```

---

## 5) Chat formatı + eğitim

> Gemma `system` rolünü sevmez. System’i user’a fold et, **`messages` kolonunu sil**, sadece `text` bırak. Yoksa SFTTrainer tekrar template uygular ve aynı hata gelir.

```python
from trl import SFTTrainer, SFTConfig

def fold_system(messages):
    """Gemma chat template rejects role=system — merge into first user turn."""
    fixed = []
    system_bits = []
    for m in messages:
        role, content = m["role"], m["content"]
        if role == "system":
            system_bits.append(content)
            continue
        if role == "user" and system_bits:
            content = "\n\n".join(system_bits) + "\n\n" + content
            system_bits = []
        fixed.append({"role": role, "content": content})
    if system_bits and not fixed:
        fixed.append({"role": "user", "content": "\n\n".join(system_bits)})
    elif system_bits:
        fixed[0]["content"] = "\n\n".join(system_bits) + "\n\n" + fixed[0]["content"]
    return fixed

def to_text(ex):
    return {
        "text": tok.apply_chat_template(
            fold_system(ex["messages"]),
            tokenize=False,
            add_generation_prompt=False,
        )
    }

# CRITICAL: drop "messages" so SFTTrainer does not re-apply chat template
train_ds = ds.map(to_text, remove_columns=ds.column_names)
print(train_ds.column_names)  # should be ['text'] only
print(train_ds[0]["text"][:200])

args = SFTConfig(
    output_dir="./navgo-lora",
    num_train_epochs=3,
    per_device_train_batch_size=1,
    gradient_accumulation_steps=8,
    learning_rate=2e-4,
    logging_steps=10,
    save_steps=100,
    packing=False,
    max_length=1024,
    dataset_text_field="text",
    # T4: GradScaler + bf16 broken — disable AMP entirely
    fp16=False,
    bf16=False,
)

trainer = SFTTrainer(
    model=model,
    args=args,
    train_dataset=train_ds,
    processing_class=tok,
)
trainer.train()
model.save_pretrained("./navgo-lora")
tok.save_pretrained("./navgo-lora")
```

Eğitim bitince `./navgo-lora` = LoRA adapter.

---

## 6) Merge (tek model dosyası)

```python
from peft import PeftModel
from transformers import AutoModelForCausalLM, AutoTokenizer
import torch

BASE = "google/gemma-2-2b-it"
base = AutoModelForCausalLM.from_pretrained(
    BASE, torch_dtype=torch.float16, device_map="auto"
)
merged = PeftModel.from_pretrained(base, "./navgo-lora")
merged = merged.merge_and_unload()

out = "./navgo-gemma-merged"
merged.save_pretrained(out)
AutoTokenizer.from_pretrained(BASE).save_pretrained(out)
print("merged →", out)
```

İstersen HF’ye de yükle:

```python
merged.push_to_hub("SENIN_USER/navgo-gemma-lora-v1")
```

---

## 7) Ollama’ya alma (PC’de)

Colab’dan `navgo-gemma-merged` klasörünü indir **veya** HF’den çek.

En pratik yol (Ollama’da Gemma + Modelfile):

1. [Ollama](https://ollama.com) kur  
2. Base’i çek: `ollama pull gemma2:2b`  
3. Şimdilik fine-tune’suz da test edebilirsin; merge’ü GGUF’a çevirmek için `llama.cpp` convert gerekir.

**Hızlı test yolu (eğitim sonrası):**  
HF’deki merged modeli `llama.cpp` / `ollama create` ile GGUF yap → örn. `navgo-gemma`.

Basit Modelfile örneği (GGUF hazırsa):

```text
FROM ./navgo-gemma-q4.gguf
PARAMETER temperature 0.2
```

```bash
ollama create navgo-gemma -f Modelfile
ollama run navgo-gemma
```

---

## 8) NavGo’ya bağla

`masterfabric-go/.env`:

```env
LLM_BASE_URL=http://127.0.0.1:11434/v1
LLM_MODEL=navgo-gemma
# veya henüz custom yoksa: gemma2:2b
```

```bash
ollama serve
# API'yi yeniden başlat
go run ./cmd/server
```

Mobil Plan → “LLM intent…” görmelisin. Yoksa şablon fallback’e düşer.

---

## Kontrol listesi

- [ ] `train_v1.jsonl` ≥ ~200 satır, TR+EN  
- [ ] System prompt = `service.go`  
- [ ] Colab T4 + QLoRA 3 epoch  
- [ ] Merge kaydedildi  
- [ ] Ollama model adı = `.env` `LLM_MODEL`  
- [ ] API log: `LLM enabled`

---

## Sık hata

| Hata | Çözüm |
|------|--------|
| Gemma 403 | HF’de Gemma lisansını kabul et |
| CUDA OOM | `batch_size=1`, `max_seq_length=512` |
| NavGo LLM kapalı | `.env` `LLM_BASE_URL` + API restart |
| JSON bozuk | Daha fazla örnek; temperature 0.2 |
| `max_seq_length` TypeError | Yeni TRL: `max_length=1024` kullan |
| `System role not supported` | `fold_system()` + `remove_columns` (sadece `text`) |
| BFloat16 GradScaler NotImplementedError | T4: `bnb_4bit_compute_dtype=torch.float16` + `fp16=True, bf16=False`; model hücresini yeniden çalıştır |
