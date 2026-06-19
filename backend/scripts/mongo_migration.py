import sqlite3
import asyncio
from motor.motor_asyncio import AsyncIOMotorClient
import os
import uuid
import re
from datetime import datetime

# Configuration
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
SQLITE_DB = os.path.join(SCRIPT_DIR, "..", "tripme.db")
MONGO_URI = "mongodb://localhost:27017"
MONGO_DB_NAME = "tripme_genesis"

def slugify(text):
    if not text:
        return str(uuid.uuid4())
    text = text.lower()
    text = re.sub(r'[^\w\s-]', '', text)
    text = re.sub(r'[\s_-]+', '-', text)
    return text.strip('-')

async def migrate():
    if not os.path.exists(SQLITE_DB):
        print(f"SQLite DB not found at {SQLITE_DB}")
        return

    # SQLite Connection
    sqlite_conn = sqlite3.connect(SQLITE_DB)
    sqlite_conn.row_factory = sqlite3.Row
    cursor = sqlite_conn.cursor()

    # MongoDB Connection
    mongo_client = AsyncIOMotorClient(MONGO_URI)
    mongo_db = mongo_client[MONGO_DB_NAME]

    print("--- Starting Migration ---")

    # 1. Fetch Categories & Districts for mapping
    cursor.execute("SELECT * FROM categories")
    categories = {row['id']: (row['name'], row['slug']) for row in cursor.fetchall()}
    
    cursor.execute("SELECT * FROM districts")
    districts = {row['id']: (row['name'], row['province']) for row in cursor.fetchall()}

    # 2. Migrate Places
    cursor.execute("SELECT * FROM places")
    places_sql = cursor.fetchall()
    
    print(f"Found {len(places_sql)} places in SQLite.")
    
    place_count = 0
    for row in places_sql:
        # Helper to get value from row safely
        def g(key, default=None):
            try:
                return row[key]
            except:
                return default

        cat_name, _ = categories.get(g('category_id'), ("General", "general"))
        dist_name, _ = districts.get(g('district_id'), ("Unknown", "Unknown"))
        
        name = g('name')
        slug = slugify(name)
        
        # Map SQLite Place -> MongoDB Place Schema
        place_doc = {
            "uuid": g('id'),
            "name": name,
            "slug": slug,
            "description": g('description'),
            "category": cat_name,
            "category_id": g('category_id'),
            "district": dist_name,
            "district_id": g('district_id'),
            "lat": g('lat'),
            "lng": g('lng'),
            "address": g('address'),
            "ticket_price": g('ticket_price', 0),
            "ticket_range": g('ticket_range'),
            "parking_fee": g('parking_fee', 0),
            "cost_min": g('cost_min'),
            "cost_max": g('cost_max'),
            "road_type": g('road_type'),
            "mobile_signal": g('mobile_signal'),
            "parking_avail": g('parking_avail', 0),
            "toilets": g('toilets', 0),
            "food_nearby": g('food_nearby', 0),
            "wheelchair_access": g('wheelchair_access', 0),
            "stairs_heavy": g('stairs_heavy', 0),
            "is_indoor": g('is_indoor', 0),
            "duration_min": g('duration_min', 60),
            "safety_level": g('safety_level', "Safe"),
            "safety_note": g('safety_note'),
            "rain_sensitivity": g('rain_sensitivity'),
            "monsoon_note": g('monsoon_note'),
            "ar_supported": g('ar_supported', 0),
            "status": g('status', "pending"),
            "source": g('data_source', "manual"),
            "external_image_url": g('external_image_url'),
            "tags": g('tags'),
            "facilities": g('facilities'),
            "crowd_level": g('crowd_level'),
            "noise_level": g('noise_level'),
            "dress_code_req": g('dress_code_req', 0),
            "createdAt": g('created_at'),
            "updatedAt": datetime.utcnow()
        }
        
        # Convert createdAt string to datetime if needed
        if isinstance(place_doc["createdAt"], str):
            try:
                place_doc["createdAt"] = datetime.fromisoformat(place_doc["createdAt"])
            except:
                place_doc["createdAt"] = datetime.utcnow()
        elif not place_doc["createdAt"]:
            place_doc["createdAt"] = datetime.utcnow()

        # Fetch associated images
        cursor.execute("SELECT * FROM place_images WHERE place_id = ?", (g('id'),))
        images_sql = cursor.fetchall()
        place_doc["images"] = [
            {
                "image_path": img['image_path'],
                "is_cover": img['is_cover']
            } for img in images_sql
        ]

        # Upsert into MongoDB
        try:
            await mongo_db.places.update_one(
                {"uuid": g('id')},
                {"$set": place_doc},
                upsert=True
            )
            place_count += 1
        except Exception as e:
            print(f"Failed to migrate {name}: {e}")

    print(f"Successfully migrated {place_count} places.")

    # 3. Migrate Users
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='users'")
    if cursor.fetchone():
        cursor.execute("SELECT * FROM users")
        users_sql = cursor.fetchall()
        for row in users_sql:
            user_doc = {
                "firebase_uid": row['firebase_uid'],
                "email": row['email'],
                "tier": row['tier'],
                "createdAt": row['created_at']
            }
            await mongo_db.users.update_one(
                {"firebase_uid": row['firebase_uid']},
                {"$set": user_doc},
                upsert=True
            )
        print(f"Migrated {len(users_sql)} users.")

    print("--- Migration Completed ---")
    sqlite_conn.close()
    mongo_client.close()

if __name__ == "__main__":
    asyncio.run(migrate())
