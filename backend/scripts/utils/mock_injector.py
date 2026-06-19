import sqlite3
import uuid
import datetime

DB_PATH = "tripme.db"

def inject_mock_data():
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()
    
    # Check if table exists
    cur.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='places'")
    if not cur.fetchone():
        print("Places table missing! Running seed first...")
        return

    mock_places = [
        ("Sigiriya Rock Fortress", "Matale", "Cultural Heritage", "Ancient rock fortress and palace ruin."),
        ("Temple of the Tooth", "Kandy", "Religious", "The sacred tooth relic of the Buddha."),
        ("Ella Nine Arch Bridge", "Badulla", "Scenic", "Famous colonial-era railway bridge."),
        ("Galle Fort", "Galle", "Historical", "Living UNESCO heritage site."),
        ("Yala National Park", "Hambantota", "Wildlife", "Leopard safari and biodiversity hotspot.")
    ]

    now = datetime.datetime.utcnow().isoformat()
    count = 0

    for name, district, category, desc in mock_places:
        cur.execute("SELECT id FROM places WHERE name = ?", (name,))
        if cur.fetchone():
            continue

        place_id = str(uuid.uuid4())
        cur.execute("""
            INSERT INTO places (id, name, district_id, category_id, description, status, approved, country, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (place_id, name, district, category, desc, "approved", 1, "Sri Lanka", now))
        count += 1

    conn.commit()
    conn.close()
    print(f"Injected {count} mock places for UI visualization.")

if __name__ == "__main__":
    inject_mock_data()
