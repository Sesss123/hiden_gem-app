import asyncio
import logging
import sys
import os

sys.path.append(os.getcwd())

from services.wikipedia_service import wikipedia_service
from core.mongodb import get_mongo_db

async def patch():
    print("Patching Sigiriya with Official Wikipedia Image...")
    db = await get_mongo_db()
    
    # Sigiriya Wikipedia Title is "Sigiriya"
    image_url = await wikipedia_service.get_page_image("Sigiriya")
    
    if not image_url:
        # Fallback to a verified static URL if Wiki fails
        image_url = "https://upload.wikimedia.org/wikipedia/commons/4/4c/Sigiriya__Lion_Rock.jpg"
        
    print(f"Using Image: {image_url}")
    
    result = await db.places.update_one(
        {"name": {"$regex": "Sigiriya Rock Fortress", "$options": "i"}},
        {
            "$set": {
                "external_image_url": image_url,
                "images": [{
                    "image_path": image_url,
                    "caption": "Sigiriya Rock Fortress - Official High Fidelity View",
                    "is_cover": 1
                }]
            }
        }
    )
    
    if result.modified_count > 0:
        print("SUCCESS: Sigiriya image updated!")
    else:
        print("WARNING: No document updated. (Check if name matches)")

if __name__ == "__main__":
    asyncio.run(patch())
