import asyncio
import logging
import sys
import os

# Adjust path to import backend modules
sys.path.append(os.getcwd())

from services.image_repair_service import image_repair_service
from core.mongodb import get_mongo_db

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("SigiriyaRepair")

async def main():
    logger.info("🏰 Starting High-Fidelity Repair for Sigiriya Rock Fortress...")
    
    db = await get_mongo_db()
    
    # Find Sigiriya
    place = await db.places.find_one({"name": {"$regex": "Sigiriya Rock Fortress", "$options": "i"}})
    
    if not place:
        logger.error("❌ Sigiriya Rock Fortress not found in MongoDB.")
        return

    place_id = str(place["_id"])
    logger.info(f"📍 Found Sigiriya with ID: {place_id}")
    
    # Perform repair
    success = await image_repair_service.repair_place_image(place_id, force=True)
    
    if success:
        logger.info("✅ Sigiriya image repair complete. Please check the dashboard.")
    else:
        logger.error("❌ Sigiriya repair failed.")

if __name__ == "__main__":
    asyncio.run(main())
