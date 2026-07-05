import logging
logger = logging.getLogger(__name__)

import sqlite3
import json

conn = sqlite3.connect('tripme.db')
cur = conn.cursor()
cur.execute("PRAGMA table_info(places)")
cols = [row[1] for row in cur.fetchall()]
logger.info(f"Columns: {cols}")

cur.execute("SELECT * FROM places LIMIT 1")
row = cur.fetchone()
if row:
    logger.info("Row data found.")
else:
    logger.info("No data in places table.")
conn.close()
