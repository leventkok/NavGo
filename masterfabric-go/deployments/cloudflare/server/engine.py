"""NavGo Transformers engine: Gemma-2-2b-it + optional LoRA adapter."""

from __future__ import annotations

import os
from typing import Any


def fold_system(messages: list[dict[str, str]]) -> list[dict[str, str]]:
    """Gemma chat template does not support system role — fold into first user."""
    fixed: list[dict[str, str]] = []
    system_bits: list[str] = []
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


class TransformersEngine:
    def __init__(
        self,
        base_model: str,
        adapter: str | None = None,
        *,
        load_in_4bit: bool = True,
        served_model: str = "navgo-gemma",
        hf_token: str | None = None,
    ) -> None:
        self.base_model = base_model
        self.adapter = (adapter or "").strip() or None
        self.load_in_4bit = load_in_4bit
        self.served_model = served_model
        self.hf_token = hf_token or os.environ.get("HF_TOKEN") or os.environ.get(
            "HUGGING_FACE_HUB_TOKEN"
        )
        self.tok = None
        self.model = None
        self.device = None
        self._ready = False

    def model_id(self) -> str:
        if self.adapter:
            return f"{self.base_model}+{self.adapter}"
        return self.base_model

    def ready(self) -> bool:
        return self._ready

    def load(self) -> None:
        import torch
        from transformers import AutoModelForCausalLM, AutoTokenizer, BitsAndBytesConfig

        token = self.hf_token
        self.tok = AutoTokenizer.from_pretrained(self.base_model, token=token)
        self.tok.pad_token = self.tok.eos_token

        load_kwargs: dict[str, Any] = {
            "device_map": "auto",
            "token": token,
        }
        if self.load_in_4bit:
            load_kwargs["quantization_config"] = BitsAndBytesConfig(
                load_in_4bit=True,
                bnb_4bit_compute_dtype=torch.float16,
                bnb_4bit_use_double_quant=True,
                bnb_4bit_quant_type="nf4",
            )
        else:
            load_kwargs["torch_dtype"] = torch.float16

        base = AutoModelForCausalLM.from_pretrained(self.base_model, **load_kwargs)
        if self.adapter:
            from peft import PeftModel

            self.model = PeftModel.from_pretrained(base, self.adapter, token=token)
        else:
            self.model = base
        self.model.eval()
        self.device = next(self.model.parameters()).device
        self._ready = True
        print(f"loaded {self.model_id()} on {self.device}")

    def generate(
        self,
        messages: list[dict[str, str]],
        *,
        max_tokens: int = 128,
        temperature: float = 0.0,
    ) -> str:
        import torch

        if not self._ready or self.tok is None or self.model is None:
            raise RuntimeError("engine not loaded")

        prompt = self.tok.apply_chat_template(
            fold_system(messages),
            tokenize=False,
            add_generation_prompt=True,
        )
        inputs = self.tok(prompt, return_tensors="pt").to(self.device)
        gen_kwargs: dict[str, Any] = {
            "max_new_tokens": max(1, min(int(max_tokens), 256)),
            "pad_token_id": self.tok.eos_token_id,
        }
        if temperature and temperature > 0:
            gen_kwargs["do_sample"] = True
            gen_kwargs["temperature"] = float(temperature)
        else:
            gen_kwargs["do_sample"] = False

        with torch.inference_mode():
            out = self.model.generate(**inputs, **gen_kwargs)
        text = self.tok.decode(
            out[0][inputs["input_ids"].shape[-1] :],
            skip_special_tokens=True,
        )
        return text.strip()
