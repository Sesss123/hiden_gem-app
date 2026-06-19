import sqlite3

DB_PATH = "tripme.db"
conn = sqlite3.connect(DB_PATH)
cur = conn.cursor()

new_cols = [
    ("ticket_range", "TEXT"),
    ("facilities", "TEXT"),
    ("ar_supported", "INTEGER DEFAULT 0"),
    ("road_type", "TEXT"),
    ("external_image_url", "TEXT")
]

for col_name, col_type in new_cols:
    try:
        print(f"Adding {col_name}...")
        cur.execute(f"ALTER TABLE places ADD COLUMN {col_name} {col_type}")
        print(f"Added {col_name}")
    except Exception as e:
        print(f"Failed to add {col_name}: {e}")

conn.commit()
conn.close()
print("Migration done.")
