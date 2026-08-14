"""OpenAI-compatible FastAPI app for NavGo LLM."""

from __future__ import annotations

import os
from typing import Any

from fastapi import FastAPI, Header, HTTPException, Request
from fastapi.responses import JSONResponse

from engine import TransformersEngine


def ensure_api_key() -> str:
    key = (os.environ.get("LLM_API_KEY") or os.environ.get("NAVGO_LLM_API_KEY") or "").strip()
    if not key:
        raise RuntimeError("LLM_API_KEY is empty — set it in the Colab config cell")
    os.environ["LLM_API_KEY"] = key
    return key


def create_app(engine: TransformersEngine, *, api_key: str | None = None) -> FastAPI:
    expected = (api_key or os.environ.get("LLM_API_KEY") or "").strip()
    app = FastAPI(title="NavGo LLM", docs_url=None, redoc_url=None)

    def check_auth(authorization: str | None) -> None:
        if not expected:
            return
        if not authorization or not authorization.startswith("Bearer "):
            raise HTTPException(status_code=401, detail={"error": {"message": "unauthorized"}})
        token = authorization.removeprefix("Bearer ").strip()
        if token != expected:
            raise HTTPException(status_code=401, detail={"error": {"message": "unauthorized"}})

    @app.get("/health")
    async def health() -> dict[str, Any]:
        return {
            "ok": True,
            "model": engine.served_model,
            "adapter": engine.adapter,
            "ready": engine.ready(),
        }

    @app.get("/v1/models")
    async def list_models(authorization: str | None = Header(default=None)) -> dict[str, Any]:
        check_auth(authorization)
        return {
            "object": "list",
            "data": [
                {
                    "id": engine.served_model,
                    "object": "model",
                    "owned_by": "navgo",
                }
            ],
        }

    @app.post("/v1/chat/completions")
    async def chat_completions(
        request: Request,
        authorization: str | None = Header(default=None),
    ) -> JSONResponse:
        check_auth(authorization)
        try:
            payload = await request.json()
        except Exception as exc:
            return JSONResponse(
                {"error": {"message": f"invalid json body: {exc}"}},
                status_code=400,
            )
        if not isinstance(payload, dict):
            return JSONResponse(
                {"error": {"message": "body must be a JSON object"}},
                status_code=400,
            )

        messages = payload.get("messages") or []
        if not isinstance(messages, list) or not messages:
            return JSONResponse(
                {"error": {"message": "messages required"}},
                status_code=400,
            )

        max_tokens = int(payload.get("max_tokens") or 128)
        temperature = float(payload.get("temperature") or 0.0)
        model_name = payload.get("model") or engine.served_model

        content = engine.generate(
            [
                {
                    "role": str(m.get("role", "user")),
                    "content": str(m.get("content", "")),
                }
                for m in messages
                if isinstance(m, dict)
            ],
            max_tokens=max_tokens,
            temperature=temperature,
        )
        return JSONResponse(
            {
                "id": "navgo-chatcmpl",
                "object": "chat.completion",
                "model": model_name,
                "choices": [
                    {
                        "index": 0,
                        "message": {"role": "assistant", "content": content},
                        "finish_reason": "stop",
                    }
                ],
            }
        )

    return app
