import asyncio
import os
import sys
import logging

# Add parent dir to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

# FIX: Migrated from legacy smart_tank_brain to UniversalDiscoveryHive
from discovery.universal_discovery_hive import UniversalDiscoveryHive
from core.mongodb import get_mongo_db

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("VerifyDiscovery")

async def verify_hive():
    logger.info("🐝 [VerifyDiscovery] Starting Discovery Hive Verification...")
    
    hive = UniversalDiscoveryHive()
    
    # Test a small sweep for a specific district to verify it works
    # We use a controlled run instead of the full master hive
    logger.info("🔍 Testing discovery logic for: Matara District...")
    
    # In the new architecture, we can test individual discovery components
    from pipeline.enrichment_manager import enrichment_manager
    test_place = "Polhena Beach"
    district = "Matara"
    
    result = await enrichment_manager.enrich_all(test_place, district)
    
    if result and result.get("score", 0) > 50:
        logger.info(f"✅ SUCCESS: Discovery pipeline is operational. Found: {result.get('name')}")
    else:
        logger.error("❌ FAILURE: Discovery pipeline returned insufficient data.")

if __name__ == "__main__":
    asyncio.run(verify_hive())
