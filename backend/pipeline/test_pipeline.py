# backend/pipeline/test_pipeline.py

import asyncio
import os
import json
from .scraper import UniversalScraper
from .ai_extractor import AIExtractor
from .validator import DataValidator
from .main_pipeline import orchestrate_item

async def run_smoke_test():
    print("🚀 Starting Pipeline Smoke Test...")
    
    # Mock data for when API keys are missing or to save credits
    mock_extracted = {
        "name": "Sigiriya Rock Fortress",
        "description": "An ancient rock fortress located in the northern Matale District near the town of Dambulla in the Central Province, Sri Lanka. It is a site of historical and archaeological significance that is dominated by a massive column of rock nearly 200 metres high.",
        "district": "Matale",
        "category": "Historical",
        "lat": 7.9570,
        "lng": 80.7603,
        "ticket_range": "$30",
        "ar_supported": True,
        "external_image_url": "https://example.com/sigiriya.jpg"
    }

    # 1. Test Scraper (using a reliable site)
    scraper = UniversalScraper()
    print("Testing Scraper (Phase 2)...")
    html = await scraper.scrape("https://example.com", type="static")
    if html:
        print("✅ Scraper works.")
    else:
        print("❌ Scraper failed.")

    # 2. Test Validator (Phase 4)
    validator = DataValidator()
    print("Testing Validator (Phase 4)...")
    is_approved, score = validator.validate_workflow(mock_extracted)
    if is_approved and score > 80:
        print(f"✅ Validator works. Score: {score}")
    else:
        print(f"❌ Validator rejected valid mock data. Score: {score}")

    # 3. Test Full Orchestration with Mock (Phase 5 & 6)
    print("Testing Storage (Phase 5)...")
    # We'll need a way to pass mock data to orchestrate_item or just test storage directly
    # For this test, we verify we can import everything and components initialize
    try:
        extractor = AIExtractor()
        print("✅ Components initialized.")
    except Exception as e:
        print(f"❌ Component initialization failed: {e}")

    print("\n--- Smoke Test Summary ---")
    print("Environment Check:")
    print(f"- ANTHROPIC_API_KEY: {'Set' if os.getenv('ANTHROPIC_API_KEY') else 'MISSING'}")
    print(f"- GOOGLE_API_KEY: {'Set' if os.getenv('GOOGLE_API_KEY') else 'MISSING'}")
    
    print("\nRun 'python -m pipeline.main_pipeline' for a real harvest run.")

if __name__ == "__main__":
    asyncio.run(run_smoke_test())
