import asyncio
import logging
from core.mongodb import get_mongo_db
from services.image_repair_service import image_repair_service
from pipeline.enrichment_manager import enrichment_manager
from pipeline.validator import DataValidator
from datetime import datetime

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("IntegrityGuard")

class IntegrityGuard:
    def __init__(self):
        self.batch_size = 5
        self.validator = DataValidator()

    async def run_clean_sweep(self):
        """
        Scans for places with missing or low-confidence vision metadata and repairs them.
        """
        logger.info("🛡️ [IntegrityGuard] Starting global visual clean sweep...")
        db = await get_mongo_db()
        
        # Query for nodes that:
        # 1. Have no vision_metadata OR
        # 2. Have match_confidence < 75 OR
        # 3. Are not validated OR
        # 4. Are marked as defective
        query = {
            "$or": [
                {"vision_metadata": {"$exists": False}},
                {"vision_metadata.match_confidence": {"$lt": 75}},
                {"vision_metadata.is_validated": False},
                {"is_defective": True}
            ]
        }
        
        cursor = db.places.find(query).limit(50) # Limit per sweep to save quota
        places = await cursor.to_list(length=50)
        
        if not places:
            logger.info("✨ [IntegrityGuard] All legacy nodes are visually sound.")
            return

        logger.info(f"🧹 [IntegrityGuard] Found {len(places)} potential legacy nodes to repair.")
        
        for place in places:
            name = place.get("name")
            place_id = str(place["_id"])
            
            logger.info(f"🛠️ [IntegrityGuard] Repairing: {name} ({place_id})")
            try:
                # 1. Image Repair (Vision AI)
                await image_repair_service.repair_place_image(place_id)
                
                # 2. Metadata Repair (Deep Enrichment)
                # If defective, trigger enrichment manager
                if place.get("is_defective"):
                    logger.info(f"🔍 [IntegrityGuard] Deep Enrichment triggered for defective node: {name}")
                    district = place.get("district", "Sri Lanka")
                    if district == "Not specified": district = "Sri Lanka"
                    
                    enriched = await enrichment_manager.enrich_all(name, district)
                    
                    # Update the place with newly found data
                    # We merge the enriched data back into the place doc
                    update_data = {k: v for k, v in enriched.items() if v and v != "Not specified"}
                    
                    # Re-calculate score
                    # Merge current record with new findings to get total score
                    merged_temp = {**place, **update_data}
                    new_score = self.validator.calculate_quality_score(merged_temp)
                    update_data["score"] = new_score
                    
                    # If score is good enough and fields are present, clear defective flag
                    if new_score >= 80 and update_data.get("district") and update_data.get("category"):
                        update_data["is_defective"] = False
                        logger.info(f"✨ [IntegrityGuard] Node cured! '{name}' is no longer defective.")
                    
                    await db.places.update_one({"_id": place["_id"]}, {"$set": update_data})

                logger.info(f"✅ [IntegrityGuard] Refined: {name}")
            except Exception as e:
                logger.error(f"❌ [IntegrityGuard] Error repairing {name}: {e}")
            
            # Throttle to respect API quotas
            await asyncio.sleep(2)

        logger.info("🏁 [IntegrityGuard] Global sweep complete.")

if __name__ == "__main__":
    guard = IntegrityGuard()
    asyncio.run(guard.run_clean_sweep())
