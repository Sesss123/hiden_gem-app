import logging
import json
import os
import io
import asyncio
from typing import Dict, Any, Optional
import google.generativeai as genai
from PIL import Image
import httpx
from core.key_rotator import multi_key_rotator

logger = logging.getLogger("VisionValidator")

class VisionValidator:
    def __init__(self):
        # Initial config with whatever key is active
        active_key = multi_key_rotator.get_active_key("google")
        if active_key:
            genai.configure(api_key=active_key)
            self.model = genai.GenerativeModel("gemini-1.5-flash") # Use Flash for speed/cost
        else:
            self.model = None
            logger.warning("[VisionValidator] No Google API key available.")

    async def verify_location_match(self, image_url: str, location_name: str, category: str) -> Dict[str, Any]:
        """
        Asks Gemini Vision: 'Does this image look like {location_name} ({category})?'
        """
        if not self.model:
            return {"match": True, "score": 1.0, "reason": "AI not available, assuming match"}

        logger.info(f"[VisionValidator] Checking image match for '{location_name}'...")

        prompt = f"""You are a travel quality inspector and feature extractor for TripMeAI.
Task: Analyze the image for the tourist attraction '{location_name}' ({category}).

### EVALUATION CRITERIA:
1. RELEVANCE: Does it actually look like '{location_name}' or the category '{category}'?
2. QUALITY: Detect blurriness (is_blurry) and lighting quality.
3. AESTHETICS: Assign an 'aesthetic_score' (0-100) based on composition, colors, and premium travel appeal.
4. FEATURES: Identify visible physical features (wheelchair access, stairs, toilets, parking, etc.).

Return ONLY JSON:
{{
  "is_match": true/false,
  "confidence": 0.0-1.0,
  "aesthetic_score": 0-100,
  "is_blurry": true/false,
  "lighting_quality": "low|fair|good|excellent",
  "visual_description": "short description",
  "features": {{
    "wheelchair_access": 0/1,
    "stairs_heavy": 0/1,
    "parking_visible": 0/1,
    "toilets_visible": 0/1,
    "food_stalls_visible": 0/1,
    "well_maintained": 0/1,
    "crowded": 0/1
  }},
  "auto_tags": ["tag1", "tag2"],
  "issues": ["list of quality or relevance issues"]
}}"""

        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                resp = await client.get(image_url)
                resp.raise_for_status()
                img = Image.open(io.BytesIO(resp.content))

            # Attempt with key rotation
            max_attempts = 3
            for attempt in range(max_attempts):
                active_key = multi_key_rotator.get_active_key("google")
                if not active_key: break
                
                genai.configure(api_key=active_key)
                try:
                    response = await self.model.generate_content_async([prompt, img])
                    text = response.text.strip()
                    
                    # Clean markdown
                    if "```" in text:
                        text = text.split("```")[1]
                        if text.startswith("json"): text = text[4:]
                    
                    result = json.loads(text)
                    multi_key_rotator.increment(active_key)
                    
                    logger.info(f"[VisionValidator] Match result: {result.get('is_match')} (Conf: {result.get('confidence')})")
                    return result
                except Exception as e:
                    if "429" in str(e):
                        multi_key_rotator.mark_exhausted(active_key, reason="Vision 429")
                        continue
                    raise e
            
            return {"is_match": True, "confidence": 0.5, "reason": "Exhausted keys, assuming match"}

        except Exception as e:
            logger.error(f"[VisionValidator] Visual check failed: {e}")
            return {"is_match": True, "confidence": 0.0, "error": str(e)}

vision_validator = VisionValidator()
