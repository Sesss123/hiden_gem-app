import json
import sqlite3
import uuid
from datetime import datetime

DB_PATH = "tripme.db"
SAMPLE_FILE = "sample_data.json"

def seed_db():
    try:
        with open(SAMPLE_FILE, 'r', encoding='utf-8') as f:
            places = json.load(f)
    except FileNotFoundError:
        print(f"Error: {SAMPLE_FILE} not found.")
        return

    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()
    
    count = 0
    now = datetime.utcnow().isoformat()
    
    for p in places:
        place_id = str(uuid.uuid4())
        
        # Check if already exists by name
        cur.execute("SELECT id FROM places WHERE name = ?", (p['name'],))
        if cur.fetchone():
            print(f"Skipping {p['name']}, already exists.")
            continue
            
        cur.execute("""
        INSERT INTO places (id,country,district,name,category,description,lat,lng,cost_min,cost_max,is_indoor,rain_note,safety_note,created_at)
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)
        """, (
            place_id, 
            p.get('country', 'Sri Lanka'), 
            p.get('district', ''), 
            p.get('name', ''), 
            p.get('category', ''), 
            p.get('description', ''),
            p.get('lat', 0.0), 
            p.get('lng', 0.0), 
            p.get('cost_min', 0), 
            p.get('cost_max', 0), 
            1 if p.get('is_indoor', False) else 0,
            p.get('rain_note', ''), 
            p.get('safety_note', ''), 
            now
        ))
        count += 1
        
    conn.commit()
    conn.close()
    print(f"Successfully seeded {count} places.")

if __name__ == "__main__":
    seed_db()
