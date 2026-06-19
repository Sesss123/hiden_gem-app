# backend/pipeline/discovery.py
# AI Intelligence Discovery — Translates prompts into scraping targets

import logging
import json
import asyncio
from typing import List, Dict, Any, Optional
import google.generativeai as genai
import os
from openai import AsyncOpenAI

from core.key_rotator import multi_key_rotator
from pipeline.logger import get_pipeline_logger
from pipeline.search_engine import search_engine

logger = get_pipeline_logger("AIDiscovery")

DISCOVERY_PROMPT = """You are the Neural Reasoning Unit for TripMeAI.
Your mission is to perform a ReAct (Reasoning and Acting) analysis on the user's travel discovery request.

User Prompt: {user_prompt}

Decompose this request into a logical plan. Think step-by-step.
Return a JSON object with:
1. "thought_process": A detailed paragraph explaining your internal reasoning, potential challenges, and strategy.
2. "plan_steps": A list of 3-5 logical steps you will take (e.g. "Search for high-authority lists", "Cross-reference with Lakdasun history", "Scrape specific place details").
3. "queries": 3-5 hyper-specific search queries using site operators (e.g. "site:lakdasun.org", "site:yamu.lk", "site:sltda.gov.lk").
4. "target_urls": A list of 2-4 authoritative URLs that you believe are the best starting points.

CRITICAL: Return ONLY valid JSON.
"""

class AIDiscovery:
    def __init__(self):
        self.model_name = "models/gemini-2.0-flash" 
    
    async def _get_model(self, model_variant: str = "gemini-2.0-flash"):
        if model_variant.startswith("claude-"):
            active_key = multi_key_rotator.get_active_key("anthropic")
            if not active_key: return None, None
            from anthropic import AsyncAnthropic
            return AsyncAnthropic(api_key=active_key), "anthropic"

        if model_variant == "gpt-4o":
            active_key = multi_key_rotator.get_active_key("openai")
            if not active_key: return None, None
            return AsyncOpenAI(api_key=active_key), "openai"
        
        if model_variant == "deepseek-chat":
            active_key = multi_key_rotator.get_active_key("deepseek")
            if not active_key: return None, None
            return AsyncOpenAI(api_key=active_key, base_url="https://api.deepseek.com"), "deepseek"
            
        if model_variant == "llama-3.3-70b-versatile":
            active_key = multi_key_rotator.get_active_key("groq")
            if not active_key: return None, None
            return AsyncOpenAI(api_key=active_key, base_url="https://api.groq.com/openai/v1"), "groq"
        
        active_key = multi_key_rotator.get_active_key("google")
        if not active_key:
            return None, None
        genai.configure(api_key=active_key)
        full_model_name = f"models/{model_variant}"
        return genai.GenerativeModel(full_model_name), active_key

    async def generate_targets(self, user_prompt: str) -> Dict[str, Any]:
        """Uses AI to find where to scrape for the given prompt with automatic key rotation."""
        from api.routes_pipeline import set_pipeline_state
        
        logger.info(f"[Discovery] Identifying targets for: '{user_prompt}'")
        prompt = DISCOVERY_PROMPT.format(user_prompt=user_prompt)
        
        # Calculate max attempts based on available keys
        status = multi_key_rotator.get_status()
        max_attempts = max(1, status.get("total_keys", 1))

        models_to_try = [
            "claude-3-5-sonnet-latest", # Anthropic — Highest intelligence
            "llama-3.3-70b-versatile", # Groq — Speed
            "deepseek-chat",           # DeepSeek fallback
            "gemini-2.0-flash",        # Gemini
            "gemini-1.5-flash",
            "gpt-4o"                   # Final safety net
        ]

        for attempt in range(1, max_attempts + 1):
            for model_variant in models_to_try:
                set_pipeline_state(current_step=f"Discovery: AI Analysis ({model_variant}) - Attempt {attempt}/{max_attempts}")
                
                model, active_key = await self._get_model(model_variant)
                if not model:
                    continue

                try:
                    text = ""
                    if model_variant.startswith("claude-"):
                        logger.info(f"[Discovery] 🧠 Shifting to {model_variant} (Anthropic)")
                        response = await model.messages.create(
                            model=model_variant,
                            max_tokens=1024,
                            messages=[{"role": "user", "content": prompt}]
                        )
                        text = response.content[0].text.strip()
                    elif model_variant in ["gpt-4o", "deepseek-chat", "llama-3.3-70b-versatile"]:
                        logger.info(f"[Discovery] 🚀 Shifting to {model_variant} ({active_key[:8]}...)")
                        response = await model.chat.completions.create(
                            model=model_variant,
                            messages=[{"role": "user", "content": prompt}],
                            response_format={"type": "json_object"}
                        )
                        text = response.choices[0].message.content.strip()
                    else:
                        response = await model.generate_content_async(prompt)
                        text = response.text.strip()
                    
                    # Clean JSON
                    if "```" in text:
                        text = text.split("```")[1]
                        if text.startswith("json"):
                            text = text[4:]
                    
                    # Some models wrap JSON in more text, let's find the first { and last }
                    start = text.find('{')
                    end = text.rfind('}')
                    if start != -1 and end != -1:
                        text = text[start:end+1]
                    
                    result = json.loads(text)
                    multi_key_rotator.increment(active_key)
                    
                    urls_count = len(result.get("target_urls", []))
                    set_pipeline_state(current_step=f"Discovery: Found {urls_count} Targets")
                    logger.info(f"[Discovery] Found {urls_count} targets on attempt {attempt} using {model_variant}.")
                    return result
                    
                except Exception as e:
                    err_str = str(e).lower()
                    is_quota = any(x in err_str for x in ["429", "quota", "resource_exhausted", "limit", "overloaded"])
                    
                    if is_quota:
                        logger.warning(f"[Discovery] 🔴 429/Quota hit on {model_variant} (Key: {active_key[:8]}...).")
                        multi_key_rotator.mark_exhausted(active_key, reason=f"Quota hit on {model_variant}", model=model_variant)
                        await asyncio.sleep(0.5)
                        break 
                    
                    logger.error(f"[Discovery] AI failed on {model_variant}: {e}")
                    if attempt == max_attempts and model_variant == models_to_try[-1]:
                        set_pipeline_state(status="failed", last_error=str(e), current_step="Discovery Failed")
                        return {"error": str(e)}
        
        return {"error": "All API keys exhausted or failed."}

    async def execute_discovery_pipeline(self, prompt: str, scheduler_instance):
        """Full orchestration with state tracking and real-time search."""
        from api.routes_pipeline import set_pipeline_state
        
        try:
            targets = await self.generate_targets(prompt)
            
            if "error" in targets:
                set_pipeline_state(status="failed", last_error=targets["error"], current_step="Fatal: No API Provider Available")
                return targets

            # 1. Gather URLs from AI knowledge (Static)
            static_urls = targets.get("target_urls", [])
            
            # 2. Perform Real-Time Search (Dynamic)
            queries = targets.get("queries", [])
            discovered_urls = []
            if queries:
                set_pipeline_state(current_step=f"Discovery: Searching Web ({len(queries)} queries)")
                discovered_urls = await search_engine.batch_search(queries)
            
            # 3. Merge and Deduplicate
            all_urls = list(set(static_urls + discovered_urls))
            
            if not all_urls:
                set_pipeline_state(status="failed", last_error="No target URLs found.", current_step="Discovery: No results")
                return {"error": "AI could not find or search for specific target URLs for this prompt."}

            logger.info(f"[Discovery] Found {len(all_urls)} total URLs ({len(static_urls)} static + {len(discovered_urls)} searched).")
            set_pipeline_state(current_step=f"Scraper: Initializing Headless Engine for {len(all_urls)} URLs")
            
            from pipeline.scheduler import PipelineScheduler
            pipeline_sched = PipelineScheduler()
            await pipeline_sched.run_pipeline(all_urls, name=f"AI Discovery: {prompt[:50]}")
            
            return {
                "success": True,
                "targets_discovered": len(all_urls),
                "static_targets": len(static_urls),
                "search_targets": len(discovered_urls),
                "reasoning": targets.get("reasoning"),
                "queries_executed": queries
            }
        except Exception as e:
            logger.error(f"[Discovery] Pipeline crash: {e}")
            set_pipeline_state(status="failed", last_error=f"Pipeline Crash: {str(e)}", current_step="System Error")
            return {"error": str(e)}
