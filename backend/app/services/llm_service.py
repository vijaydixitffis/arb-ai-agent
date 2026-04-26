"""
Unified LLM Service supporting both OpenAI and Gemini
"""

import os
import json
import logging
import asyncio
from typing import Dict, Any, Optional
from app.core.config import settings

# OpenAI imports
from openai import AsyncOpenAI

# Gemini imports
import google.generativeai as genai
import google.ai.generativelanguage as glm

logger = logging.getLogger(__name__)

class LLMService:
    """Unified LLM service that can use either OpenAI or Gemini"""
    
    def __init__(self):
        self.provider = settings.LLM_PROVIDER.lower()
        
        if self.provider == "openai":
            self.openai_client = AsyncOpenAI(api_key=settings.OPENAI_API_KEY)
        elif self.provider == "gemini":
            # Force REST transport to fix IPv6 hanging issues
            # See: https://github.com/google-gemini/generative-ai-python/issues
            genai.configure(
                api_key=settings.GEMINI_API_KEY,
                transport="rest"  # Force REST instead of default (prevents IPv6 stalls)
            )
            self.gemini_model = genai.GenerativeModel(settings.GEMINI_MODEL)
        else:
            raise ValueError(f"Unsupported LLM provider: {self.provider}")
    
    async def generate_completion(
        self,
        prompt: str,
        system_prompt: Optional[str] = None,
        temperature: float = 0.1,
        max_tokens: int = 4000,
        timeout: int = 30  # 30 second timeout for faster failure detection
    ) -> Dict[str, Any]:
        """Generate completion using configured LLM provider"""
        
        logger.info(f"[LLM] Generating completion with {self.provider}, prompt length: {len(prompt)} chars")
        logger.debug(f"[LLM] Prompt preview: {prompt[:200]}...")
        
        try:
            if self.provider == "openai":
                result = await asyncio.wait_for(
                    self._openai_completion(prompt, system_prompt, temperature, max_tokens),
                    timeout=timeout
                )
            elif self.provider == "gemini":
                result = await asyncio.wait_for(
                    self._gemini_completion(prompt, system_prompt, temperature, max_tokens),
                    timeout=timeout
                )
            else:
                raise ValueError(f"Unsupported LLM provider: {self.provider}")
            
            logger.info(f"[LLM] Completion successful, tokens used: {result.get('tokens_used', 'N/A')}")
            return result
            
        except asyncio.TimeoutError:
            logger.error(f"[LLM] Completion timed out after {timeout}s")
            raise Exception(f"LLM request timed out after {timeout} seconds")
        except Exception as e:
            logger.error(f"[LLM] Completion failed: {str(e)}")
            raise
    
    async def _openai_completion(
        self,
        prompt: str,
        system_prompt: Optional[str],
        temperature: float,
        max_tokens: int
    ) -> Dict[str, Any]:
        """Generate completion using OpenAI"""
        
        messages = []
        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})
        messages.append({"role": "user", "content": prompt})
        
        response = await self.openai_client.chat.completions.create(
            model=settings.OPENAI_MODEL,
            messages=messages,
            temperature=temperature,
            max_tokens=max_tokens
        )
        
        return {
            "content": response.choices[0].message.content,
            "tokens_used": response.usage.total_tokens if response.usage else 0,
            "model": settings.OPENAI_MODEL,
            "provider": "openai"
        }
    
    async def _gemini_completion(
        self,
        prompt: str,
        system_prompt: Optional[str],
        temperature: float,
        max_tokens: int
    ) -> Dict[str, Any]:
        """Generate completion using Gemini (run in thread pool to avoid blocking)"""
        
        logger.info(f"[LLM-GEMINI] Starting Gemini completion with model: {settings.GEMINI_MODEL}")
        
        # Combine system and user prompts for Gemini
        full_prompt = prompt
        if system_prompt:
            full_prompt = f"System Instructions:\n{system_prompt}\n\nUser Request:\n{prompt}"
        
        logger.debug(f"[LLM-GEMINI] Full prompt length: {len(full_prompt)} chars")
        
        # Configure generation parameters
        generation_config = {
            "temperature": temperature,
            "max_output_tokens": max_tokens,
        }
        
        def _call_gemini_sync():
            """Synchronous Gemini API call - run in thread pool"""
            try:
                logger.info("[LLM-GEMINI] Calling Gemini API (in thread pool)...")
                response = self.gemini_model.generate_content(
                    full_prompt,
                    generation_config=generation_config
                )
                
                # Check if response has content
                if not hasattr(response, 'text') or response.text is None:
                    logger.error(f"[LLM-GEMINI] Response has no text attribute or text is None!")
                    logger.error(f"[LLM-GEMINI] Response object: {response}")
                    raise ValueError("Gemini response has no content")
                
                logger.info(f"[LLM-GEMINI] Gemini response received, length: {len(response.text)} chars")
                
                tokens_used = 0
                if hasattr(response, 'usage_metadata') and response.usage_metadata:
                    tokens_used = response.usage_metadata.total_token_count
                    logger.info(f"[LLM-GEMINI] Token usage: {tokens_used}")
                
                return {
                    "content": response.text,
                    "tokens_used": tokens_used,
                    "model": settings.GEMINI_MODEL,
                    "provider": "gemini"
                }
            except Exception as e:
                logger.error(f"[LLM-GEMINI] Gemini API error: {str(e)}")
                raise
        
        try:
            # Run the blocking call in a thread pool to avoid blocking the event loop
            result = await asyncio.to_thread(_call_gemini_sync)
            return result
        except Exception as e:
            logger.error(f"[LLM-GEMINI] Thread pool error: {str(e)}")
            raise
    
    async def generate_embedding(self, text: str) -> list:
        """Generate embedding using configured provider"""
        
        if self.provider == "openai":
            return await self._openai_embedding(text)
        elif self.provider == "gemini":
            return await self._gemini_embedding(text)
    
    async def _openai_embedding(self, text: str) -> list:
        """Generate embedding using OpenAI"""
        
        response = await self.openai_client.embeddings.create(
            model=settings.OPENAI_EMBEDDING_MODEL,
            input=text
        )
        
        return response.data[0].embedding
    
    async def _gemini_embedding(self, text: str) -> list:
        """Generate embedding using Gemini"""
        
        # Use Gemini's embedding model
        embedding_model = genai.GenerativeModel(settings.GEMINI_EMBEDDING_MODEL)
        
        # Note: Gemini embedding API might differ - this is a placeholder
        # You may need to adjust based on actual Gemini embedding API
        response = embedding_model.embed_content(text)
        
        return response.embedding

# Global LLM service instance
llm_service = LLMService()
