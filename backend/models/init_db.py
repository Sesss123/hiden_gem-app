import sqlite3
import os
import uuid
from .db import DB_PATH

def init_db():
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()
    
    # 1. Districts Table
    cur.execute("""
    CREATE TABLE IF NOT EXISTS districts (
        id TEXT PRIMARY KEY,
        name TEXT UNIQUE NOT NULL,
        province TEXT
    )
    """)
    
    # 2. Categories Table
    cur.execute("""
    CREATE TABLE IF NOT EXISTS categories (
        id TEXT PRIMARY KEY,
        name TEXT UNIQUE NOT NULL,
        slug TEXT UNIQUE NOT NULL
    )
    """)
    
    # 3. District-Categories Mapping
    cur.execute("""
    CREATE TABLE IF NOT EXISTS district_categories (
        district_id TEXT,
        category_id TEXT,
        PRIMARY KEY (district_id, category_id),
        FOREIGN KEY (district_id) REFERENCES districts (id),
        FOREIGN KEY (category_id) REFERENCES categories (id)
    )
    """)

    # 4. Places Table
    cur.execute("""
    CREATE TABLE IF NOT EXISTS places (
        id TEXT PRIMARY KEY,
        country TEXT DEFAULT 'Sri Lanka',
        district_id TEXT,
        category_id TEXT,
        name TEXT NOT NULL,
        description TEXT,
        lat REAL,
        lng REAL,
        cost_min INTEGER,
        cost_max INTEGER,
        is_indoor INTEGER,
        rain_note TEXT,
        safety_note TEXT,
        created_at TEXT,
        duration_min INTEGER,
        best_time TEXT,
        open_hours TEXT,
        closed_day TEXT,
        tags TEXT,
        crowd_level TEXT,
        noise_level TEXT,
        ticket_price INTEGER,
        food_avg_per_person INTEGER,
        parking_fee INTEGER,
        extra_cost_notes TEXT,
        address TEXT,
        nearby_places TEXT,
        safety_level TEXT,
        safety_reason TEXT,
        scam_warning TEXT,
        dress_code_req INTEGER,
        special_rules TEXT,
        wheelchair_access INTEGER,
        stairs_heavy INTEGER,
        long_walk TEXT,
        toilets INTEGER,
        parking_avail INTEGER,
        food_nearby INTEGER,
        cash_only INTEGER,
        mobile_signal TEXT,
        outdoor_heavy INTEGER,
        rain_sensitivity TEXT,
        best_season TEXT,
        monsoon_note TEXT,
        data_source TEXT,
        verified INTEGER,
        last_verified_at TEXT,
        status TEXT,
        admin_notes TEXT,
        ai_summary TEXT,
        source_id TEXT,
        embedding_text TEXT,
        ticket_range TEXT,
        facilities TEXT,
        ar_supported INTEGER DEFAULT 0,
        road_type TEXT,
        external_image_url TEXT,
        ar_model_url TEXT,
        ar_brand_name TEXT,
        ar_model_scale REAL DEFAULT 1.0,
        audio_url_si TEXT,
        audio_url_en TEXT,
        ar_hotspots TEXT,
        FOREIGN KEY (district_id) REFERENCES districts (id),
        FOREIGN KEY (category_id) REFERENCES categories (id),
        UNIQUE(name, district_id, country)
    )
    """)

    # 5. Place Images
    cur.execute("""
    CREATE TABLE IF NOT EXISTS place_images (
        id TEXT PRIMARY KEY,
        place_id TEXT,
        image_path TEXT,
        thumbnail_path TEXT,
        created_at TEXT,
        caption TEXT,
        image_type TEXT,
        is_cover INTEGER,
        FOREIGN KEY (place_id) REFERENCES places (id)
    )
    """)

    # 6. Pipeline Runs Table
    cur.execute("""
    CREATE TABLE IF NOT EXISTS pipeline_runs (
        id TEXT PRIMARY KEY,
        start_time TEXT,
        end_time TEXT,
        status TEXT,
        total_scraped INTEGER,
        total_extracted INTEGER,
        total_approved INTEGER,
        total_rejected INTEGER,
        logs TEXT
    )
    """)

    # 7. Visitor Analytics Table
    cur.execute("""
    CREATE TABLE IF NOT EXISTS visitor_analytics (
        id TEXT PRIMARY KEY,
        place_id TEXT,
        type TEXT,
        search_term TEXT,
        timestamp TEXT,
        session_id TEXT,
        meta_data TEXT,
        FOREIGN KEY (place_id) REFERENCES places (id)
    )
    """)

    # 8. Users Table
    cur.execute("""
    CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        firebase_uid TEXT UNIQUE NOT NULL,
        email TEXT NOT NULL,
        tier TEXT DEFAULT 'free',
        created_at TEXT
    )
    """)

    # 9. Subscriptions Table
    cur.execute("""
    CREATE TABLE IF NOT EXISTS subscriptions (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        provider TEXT,
        external_id TEXT,
        status TEXT,
        expires_at TEXT,
        created_at TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id)
    )
    """)

    # 10. User Favorites Table
    cur.execute("""
    CREATE TABLE IF NOT EXISTS user_favorites (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        place_id TEXT,
        created_at TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (place_id) REFERENCES places (id)
    )
    """)

    # 11. User History Table
    cur.execute("""
    CREATE TABLE IF NOT EXISTS user_history (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        place_id TEXT,
        visited_at TEXT,
        notes TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (place_id) REFERENCES places (id)
    )
    """)

    conn.commit()

    # --- Migration Logic for Existing Databases ---
    # Add columns if they don't exist
    new_cols = [
        ("ar_model_url", "TEXT"),
        ("ar_brand_name", "TEXT"),
        ("ar_model_scale", "REAL DEFAULT 1.0"),
        ("audio_url_si", "TEXT"),
        ("audio_url_en", "TEXT"),
        ("ar_hotspots", "TEXT")
    ]
    
    for col_name, col_type in new_cols:
        try:
            cur.execute(f"ALTER TABLE places ADD COLUMN {col_name} {col_type}")
        except sqlite3.OperationalError:
            # Column already exists
            pass

    conn.commit()
    seed_data(conn)
    conn.close()

def seed_data(conn):
    cur = conn.cursor()
    # categories
    cats = [
        ("Heritage & Culture", "heritage_culture"),
        ("Temples & Religious", "temple_religious"),
        ("Nature & Scenic", "nature_scenic"),
        ("Wildlife & Safari", "wildlife_safari"),
        ("Beach & Coastal", "beach_coastal"),
        ("Waterfalls & Rivers", "waterfall_river"),
        ("Hiking & Viewpoints", "hiking_viewpoints"),
        ("Adventure & Outdoor", "adventure_outdoor"),
        ("Museums & Indoor", "museum_indoor"),
        ("Food & Cafés", "food_cafe"),
        ("City & Shopping", "city_shopping"),
        ("Family & Kids", "family_kids"),
        ("Hotels & Stays", "hotels_stays"),
        ("Nightlife", "nightlife")
    ]
    cat_map = {}
    for name, slug in cats:
        cid = str(uuid.uuid5(uuid.NAMESPACE_DNS, slug))
        cur.execute("INSERT OR IGNORE INTO categories (id, name, slug) VALUES (?, ?, ?)", (cid, name, slug))
        cat_map[slug] = cid

    # districts
    districts = [
        ("Ampara", "Eastern"), ("Anuradhapura", "North Central"), ("Badulla", "Uva"),
        ("Batticaloa", "Eastern"), ("Colombo", "Western"), ("Galle", "Southern"),
        ("Gampaha", "Western"), ("Hambantota", "Southern"), ("Jaffna", "Northern"),
        ("Kalutara", "Western"), ("Kandy", "Central"), ("Kegalle", "Sabaragamuwa"),
        ("Kilinochchi", "Northern"), ("Kurunegala", "North Western"), ("Mannar", "Northern"),
        ("Matale", "Central"), ("Matara", "Southern"), ("Moneragala", "Uva"),
        ("Mullaitivu", "Northern"), ("Nuwara Eliya", "Central"), ("Polonnaruwa", "North Central"),
        ("Puttalam", "North Western"), ("Ratnapura", "Sabaragamuwa"), ("Trincomalee", "Eastern"),
        ("Vavuniya", "Northern")
    ]
    district_map = {}
    for name, province in districts:
        did = str(uuid.uuid5(uuid.NAMESPACE_DNS, name.lower()))
        cur.execute("INSERT OR IGNORE INTO districts (id, name, province) VALUES (?, ?, ?)", (did, name, province))
        district_map[name] = did

    conn.commit()
