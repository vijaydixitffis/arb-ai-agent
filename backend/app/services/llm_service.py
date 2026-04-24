"""
Unified LLM Service supporting both OpenAI and Gemini
"""

import os
import json
from typing import Dict, Any, Optional
from app.core.config import settings

# OpenAI imports
from openai import AsyncOpenAI

# Gemini imports
import google.generativeai as genai
import google.ai.generativelanguage as glm

class LLMService:
    """Unified LLM service that can use either OpenAI or Gemini"""
    
    def __init__(self):
        self.provider = settings.LLM_PROVIDER.lower()
        
        if self.provider == "openai":
            self.openai_client = AsyncOpenAI(api_key=settings.OPENAI_API_KEY)
        elif self.provider == "gemini":
            genai.configure(api_key=settings.GEMINI_API_KEY)
            self.gemini_model = genai.GenerativeModel(settings.GEMINI_MODEL)
        else:
            raise ValueError(f"Unsupported LLM provider: {self.provider}")
    
    async def generate_completion(
        self,
        prompt: str,
        system_prompt: Optional[str] = None,
        temperature: float = 0.1,
        max_tokens: int = 4000
    ) -> Dict[str, Any]:
        """Generate completion using configured LLM provider"""
        
        if self.provider == "openai":
            return await self._openai_completion(
                prompt, system_prompt, temperature, max_tokens
            )
        elif self.provider == "gemini":
            return await self._gemini_completion(
                prompt, system_prompt, temperature, max_tokens
            )
    
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
        """Generate completion using Gemini"""
        
        # Combine system and user prompts for Gemini
        full_prompt = prompt
        if system_prompt:
            full_prompt = f"System Instructions:\n{system_prompt}\n\nUser Request:\n{prompt}"
        
        # Configure generation parameters
        generation_config = {
            "temperature": temperature,
            "max_output_tokens": max_tokens,
        }
        
        response = self.gemini_model.generate_content(
            full_prompt,
            generation_config=generation_config
        )
        
        return {
            "content": response.text,
            "tokens_used": response.usage_metadata.total_token_count if hasattr(response, 'usage_metadata') else 0,
            "model": settings.GEMINI_MODEL,
            "provider": "gemini"
        }
    
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
