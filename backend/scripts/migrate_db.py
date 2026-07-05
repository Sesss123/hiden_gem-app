import logging
logger = logging.getLogger(__name__)

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
        logger.info(f"Adding {col_name}...")
        cur.execute(f"ALTER TABLE places ADD COLUMN {col_name} {col_type}")
        logger.info(f"Added {col_name}")
    except Exception as e:
        logger.info(f"Failed to add {col_name}: {e}")

conn.commit()
conn.close()
logger.info("Migration done.")
