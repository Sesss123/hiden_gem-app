import asyncio
import sys
import os
import uuid
from datetime import datetime

sys.path.append(os.getcwd())

from pipeline.smart_intake_service import smart_intake_service
from core.database import SessionLocal
from models.database_models import Place

async def test_auto_approval_insertion():
    print("[TEST] Verifying Auto-Approval and SQLite Persistence...")
    
    # Mock data with 95% score
    mock_data = {
        "name": f"Auto Test Site {uuid.uuid4().hex[:4]}",
        "district": "Matale",
        "category": "Historical",
        "description": "A high-confidence test site.",
        "lat": 7.8,
        "lng": 80.6,
        "_score": 95,  # Should trigger auto-approval
        "data_source": "http://test.com",
        "financials": {"ticket_range": "500 - 1000 LKR"},
        "climate_safety": {"safety_level": "Safe", "safety_note": "Clear sky."}
    }
    
    # 1. Trigger Intake
    await smart_intake_service._genesis_intake(mock_data)
    
    # 2. Verify in SQLite
    db = SessionLocal()
    try:
        place = db.query(Place).filter(Place.name == mock_data["name"]).first()
        assert place is not None, "Place was not saved to SQLite!"
        assert place.status == "approved", f"Status expected 'approved', got '{place.status}'"
        assert place.verified == 1, "Place 'verified' flag should be 1"
        
        print(f"✅ Auto-Approval Verification Passed! Site: {place.name} | Status: {place.status}")
        
        # Cleanup
        db.delete(place)
        db.commit()
    except Exception as e:
        print(f"❌ Verification Failed: {e}")
        raise e
    finally:
        db.close()

if __name__ == "__main__":
    asyncio.run(test_auto_approval_insertion())
