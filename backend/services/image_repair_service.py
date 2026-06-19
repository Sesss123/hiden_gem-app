import logging
import asyncio
from typing import Optional, List, Dict
from core.mongodb import get_mongo_db
from pipeline.ai_extractor import AIExtractor
from pipeline.search_engine import search_engine
from services.wikipedia_service import wikipedia_service

logger = logging.getLogger("ImageRepair")

class ImageRepairService:
    def __init__(self):
        self.extractor = AIExtractor()

    async def validate_image(self, place_name: str, image_url: str) -> Optional[dict]:
        """Uses Vision AI to check if an image is relevant to a place."""
        if not image_url: return None
        
        try:
            result = await self.extractor.analyze_image_features(image_url, place_name)
            return result
        except Exception as e:
            logger.error(f"❌ Vision validation failed for {place_name}: {e}")
            return None

    async def repair_place_image(self, place_id: str, force: bool = False):
        """
        Scans a place, validates its image, and repairs it if relevance is low.
        """
        db = await get_mongo_db()
        from bson import ObjectId
        
        query = {"_id": ObjectId(place_id)} if ObjectId.is_valid(place_id) else {"uuid": place_id}
        place = await db.places.find_one(query)
        
        if not place:
            logger.error(f"❌ Place {place_id} not found for repair.")
            return False

        name = place["name"]
        current_url = place.get("external_image_url") or (place.get("images") and place["images"][0].get("image_path"))
        
        # 1. Validate current image
        if current_url and not force:
            logger.info(f"🔍 Validating current image for: {name}")
            reliability = await self.validate_image(name, current_url)
            
            if reliability and reliability.get("match_confidence", 0) >= 75:
                logger.info(f"✅ Image is already high-fidelity for {name} ({reliability['match_confidence']}%).")
                # Update metadata if missing
                await db.places.update_one(query, {"$set": {"vision_metadata": reliability}})
                return True
            else:
                logger.warning(f"⚠️ Low relevance detected for {name}. Triggering repair...")

        # 2. Search for candidates
        logger.info(f"🖼️ Searching new images for: {name}")
        
        candidates_urls = []
        
        # Priority A: Wikipedia (Try full name and short name)
        search_names = [name, name.split(" Fortress")[0], name.split(" Rock")[0], name.split(" Temple")[0]]
        for s_name in list(dict.fromkeys(search_names)): # Deduplicate
             wiki_img = await wikipedia_service.get_page_image(s_name)
             if wiki_img:
                 candidates_urls.append(wiki_img)
                 logger.info(f"📖 Found Wikipedia candidate for {s_name}")
                 break

        # Priority B: Web Search
        if len(candidates_urls) < 3:
            s_query = f"{name} scenic photography high resolution"
            web_candidates = await search_engine.search_images(s_query, max_results=5)
            for cand in web_candidates:
                if cand.get("image"):
                    candidates_urls.append(cand["image"])
        
        best_candidate = None
        best_score = 0
        best_metadata = {}

        for url in candidates_urls:
            logger.info(f"🧪 Testing candidate: {url[:60]}")
            val = await self.validate_image(name, url)
            
            if val and val.get("match_confidence", 0) > best_score:
                best_score = val["match_confidence"]
                best_candidate = url
                best_metadata = val
            
            if best_score >= 90: break # Good enough

        # 3. Apply Repair
        if best_candidate and best_score >= 70:
            logger.info(f"🚀 Found superior image for {name} (Score: {best_score}%)")
            
            # Update place
            await db.places.update_one(query, {
                "$set": {
                    "external_image_url": best_candidate,
                    "vision_metadata": best_metadata,
                    "updated_at": asyncio.get_event_loop().time() # or datetime.utcnow
                }
            })
            
            # Handle list of images if it exists
            if "images" in place:
                new_img_obj = {
                    "image_path": best_candidate,
                    "caption": f"Verified image of {name}",
                    "is_cover": 1
                }
                await db.places.update_one(query, {"$set": {"images": [new_img_obj]}})

            return True
        else:
            logger.error(f"❌ Could not find a suitable replacement for {name}")
            return False

image_repair_service = ImageRepairService()
