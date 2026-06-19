import asyncio
import sys
import os
sys.path.append(os.getcwd())
from pipeline.ai_extractor import AIExtractor

async def test_weighted_scoring():
    extractor = AIExtractor()
    
    # CASE 1: Perfect Alignment (100%)
    d1 = {"name": "Test Site", "district": "Matale", "lat": 7.5, "lng": 80.5}
    d2 = {"name": "test site", "district": "MATALE", "lat": 7.50001, "lng": 80.50001}
    
    score = await extractor.calculate_confidence_score(d1, d2)
    assert score == 100.0, f"Expected 100, got {score}"
    
    # CASE 2: Name Mismatch (-50)
    d3 = {"name": "Wrong Site", "district": "Matale", "lat": 7.5, "lng": 80.5}
    score = await extractor.calculate_confidence_score(d1, d3)
    assert score == 50.0, f"Expected 50 (District 30 + Coords 20), got {score}"

    # CASE 3: District Mismatch (-30)
    d4 = {"name": "Test Site", "district": "Kandy", "lat": 7.5, "lng": 80.5}
    score = await extractor.calculate_confidence_score(d1, d4)
    assert score == 70.0, f"Expected 70 (Name 50 + Coords 20), got {score}"

    # CASE 4: Coords Mismatch (-20)
    d5 = {"name": "Test Site", "district": "Matale", "lat": 8.5, "lng": 81.5}
    score = await extractor.calculate_confidence_score(d1, d5)
    assert score == 80.0, f"Expected 80 (Name 50 + District 30), got {score}"

    print("\n✅ Scoring Logic Verification Passed!")

if __name__ == "__main__":
    asyncio.run(test_weighted_scoring())
