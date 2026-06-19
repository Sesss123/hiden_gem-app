import asyncio
import os
import sys
import logging
from datetime import datetime

# Add parent dir to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from pipeline.scheduler import global_scheduler as scheduler
from core.mongodb import get_mongo_db

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("E2ETest")

async def test_pipeline_flow():
    logger.info("🚀 Starting E2E Pipeline Test...")
    
    # Test URL - A known Sri Lankan attraction
    test_urls = ["https://en.wikipedia.org/wiki/Sigiriya"]
    
    # Trigger run
    logger.info(f"Triggering pipeline for {test_urls}")
    await scheduler.run_pipeline(test_urls, name="E2E Integration Test")
    
    # Verify in DB
    db = await get_mongo_db()
    sigiriya = await db.places.find_one({"name": {"$regex": "Sigiriya", "$options": "i"}})
    
    if sigiriya:
        logger.info(f"✅ SUCCESS: 'Sigiriya' found in MongoDB.")
        logger.info(f"Details: Score={sigiriya.get('quality_score')}, Status={sigiriya.get('status')}")
        
        # Verify geofencing
        lat = sigiriya.get("lat")
        lng = sigiriya.get("lng")
        if 5.72 <= lat <= 9.85 and 79.52 <= lng <= 81.88:
            logger.info(f"✅ SUCCESS: Coordinates ({lat}, {lng}) are within Sri Lanka geofence.")
        else:
            logger.error(f"❌ FAILURE: Coordinates ({lat}, {lng}) failed geofencing!")
    else:
        logger.error("❌ FAILURE: 'Sigiriya' was not saved to MongoDB. Check logs.")

if __name__ == "__main__":
    if not os.getenv("GOOGLE_API_KEY"):
        logger.error("❌ FAILURE: GOOGLE_API_KEY environment variable missing.")
        sys.exit(1)
        
    asyncio.run(test_pipeline_flow())
