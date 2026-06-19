import sqlite3
import json
import os

DB_PATH = "tripme.db"

def generate_kb():
    print("--- Generating TripMe AI Knowledge Base ---")
    
    if not os.path.exists(DB_PATH):
        print(f"Error: {DB_PATH} not found.")
        return

    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    cur = conn.cursor()
    
    # Fetch Approved Places
    cur.execute("""
        SELECT p.*, d.name as district_name, c.name as category_name 
        FROM places p
        JOIN districts d ON p.district_id = d.id
        JOIN categories c ON p.category_id = c.id
        WHERE p.status = 'approved'
    """)
    rows = cur.fetchall()
    
    kb_data = []
    for r in rows:
        place = dict(r)
        # Fetch Images
        cur.execute("SELECT image_path, caption, image_type, is_cover FROM place_images WHERE place_id = ?", (place['id'],))
        place['images'] = [dict(img) for img in cur.fetchall()]
        kb_data.append(place)
        
    conn.close()

    # 1. Generate JSON KB
    with open("tripme_kb.json", "w", encoding="utf-8") as f:
        json.dump(kb_data, f, indent=4)
    print(f"Created tripme_kb.json with {len(kb_data)} entries.")

    # 2. Generate Dart KB (Optional constant for Flutter)
    dart_content = "class TripMeKB {\n  static const List<Map<String, dynamic>> places = "
    dart_content += json.dumps(kb_data, indent=4)
    dart_content += ";\n}\n"
    
    with open("tripme_kb.dart", "w", encoding="utf-8") as f:
        f.write(dart_content)
    print(f"Created tripme_kb.dart for Flutter inclusion.")

if __name__ == "__main__":
    generate_kb()
