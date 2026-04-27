"""
Unified LLM Service supporting OpenAI and Gemini.

Key guarantees:
- Gemini: uses system_instruction (separate field) + response_mime_type=application/json
- OpenAI: uses response_format=json_object
- Both: parse_json_from_llm() strips any stray markdown fences before JSON.parse
"""

import json
import logging
import re
import asyncio
from typing import Dict, Any, Optional

from app.core.config import settings
from openai import AsyncOpenAI
from google import genai
from google.genai import types as genai_types

logger = logging.getLogger(__name__)


class LLMService:
    """Unified LLM service — OpenAI or Gemini, configured via LLM_PROVIDER setting."""

    def __init__(self):
        self.provider = settings.LLM_PROVIDER.lower()

        if self.provider == "openai":
            self.openai_client = AsyncOpenAI(api_key=settings.OPENAI_API_KEY)
        elif self.provider == "gemini":
            self.gemini_client = genai.Client(api_key=settings.GEMINI_API_KEY)
        else:
            raise ValueError(f"Unsupported LLM provider: {self.provider}")

    # ── Public API ────────────────────────────────────────────────────────────

    async def generate_completion(
        self,
        prompt: str,
        system_prompt: Optional[str] = None,
        temperature: float = 0.3,
        max_tokens: int = 8192,
        timeout: int = 120,
    ) -> Dict[str, Any]:
        """Generate a JSON-mode completion via the configured LLM provider."""
        logger.info(
            f"[LLM] generate_completion provider={self.provider} "
            f"prompt_len={len(prompt)} system_len={len(system_prompt or '')}"
        )
        try:
            if self.provider == "openai":
                coro = self._openai_completion(prompt, system_prompt, temperature, max_tokens)
            elif self.provider == "gemini":
                coro = self._gemini_completion(prompt, system_prompt, temperature, max_tokens)
            else:
                raise ValueError(f"Unsupported LLM provider: {self.provider}")

            result = await asyncio.wait_for(coro, timeout=timeout)
            logger.info(f"[LLM] OK tokens_used={result.get('tokens_used', 0)}")
            return result

        except asyncio.TimeoutError:
            raise RuntimeError(f"LLM request timed out after {timeout}s")
        except Exception:
            logger.exception("[LLM] generate_completion failed")
            raise

    @staticmethod
    def parse_json_from_llm(raw: str) -> Any:
        """Strip markdown code fences then parse JSON.
        Works whether or not the LLM wraps its output in ```json ... ```.
        """
        cleaned = re.sub(r"^```(?:json)?\s*", "", raw.strip(), flags=re.MULTILINE)
        cleaned = re.sub(r"\s*```\s*$", "", cleaned.strip(), flags=re.MULTILINE)
        return json.loads(cleaned.strip())

    async def generate_embedding(self, text: str) -> list:
        if self.provider == "openai":
            return await self._openai_embedding(text)
        return await self._gemini_embedding(text)

    # ── OpenAI ────────────────────────────────────────────────────────────────

    async def _openai_completion(
        self,
        prompt: str,
        system_prompt: Optional[str],
        temperature: float,
        max_tokens: int,
    ) -> Dict[str, Any]:
        messages = []
        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})
        messages.append({"role": "user", "content": prompt})

        response = await self.openai_client.chat.completions.create(
            model=settings.OPENAI_MODEL,
            messages=messages,
            temperature=temperature,
            max_tokens=max_tokens,
            response_format={"type": "json_object"},  # enforce JSON output
        )
        return {
            "content": response.choices[0].message.content,
            "tokens_used": response.usage.total_tokens if response.usage else 0,
            "model": settings.OPENAI_MODEL,
            "provider": "openai",
        }

    async def _openai_embedding(self, text: str) -> list:
        response = await self.openai_client.embeddings.create(
            model=settings.OPENAI_EMBEDDING_MODEL,
            input=text,
        )
        return response.data[0].embedding

    # ── Gemini ────────────────────────────────────────────────────────────────

    async def _gemini_completion(
        self,
        prompt: str,
        system_prompt: Optional[str],
        temperature: float,
        max_tokens: int,
    ) -> Dict[str, Any]:
        """Call Gemini with system_instruction separate from user content,
        and response_mime_type='application/json' to force structured output."""

        config = genai_types.GenerateContentConfig(
            temperature=temperature,
            max_output_tokens=max_tokens,
            response_mime_type="application/json",
            system_instruction=system_prompt or "",
        )

        logger.info(f"[LLM-GEMINI] calling model={settings.GEMINI_MODEL}")
        response = await self.gemini_client.aio.models.generate_content(
            model=settings.GEMINI_MODEL,
            contents=prompt,   # user content only — system goes in config
            config=config,
        )

        # Guard against safety blocks or empty candidates
        candidate = (response.candidates or [None])[0]
        if candidate is None:
            block_reason = getattr(response.prompt_feedback, "block_reason", "unknown")
            raise RuntimeError(f"Gemini returned no candidates (blockReason={block_reason})")
        if getattr(candidate, "finish_reason", None) == "SAFETY":
            raise RuntimeError("Gemini response blocked by safety filters")

        content = response.text
        if not content:
            raise ValueError("Gemini response has no content")

        tokens_used = 0
        if response.usage_metadata:
            tokens_used = response.usage_metadata.total_token_count or 0

        return {
            "content": content,
            "tokens_used": tokens_used,
            "model": settings.GEMINI_MODEL,
            "provider": "gemini",
        }

    async def _gemini_embedding(self, text: str) -> list:
        response = await self.gemini_client.aio.models.embed_content(
            model=settings.GEMINI_EMBEDDING_MODEL,
            contents=text,
        )
        return response.embeddings[0].values


# Module-level singleton
llm_service = LLMService()
