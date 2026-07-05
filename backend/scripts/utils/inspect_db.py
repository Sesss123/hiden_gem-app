import logging
logger = logging.getLogger(__name__)

import sqlite3
import os

DB_PATH = "tripme.db"
if not os.path.exists(DB_PATH):
    logger.info(f"File not found: {DB_PATH}")
    exit(1)

conn = sqlite3.connect(DB_PATH)
cursor = conn.cursor()

logger.info("Districts:")
cursor.execute("SELECT * FROM districts LIMIT 5")
logger.info(cursor.fetchall())

logger.info("\nCategories:")
cursor.execute("SELECT * FROM categories LIMIT 5")
logger.info(cursor.fetchall())

conn.close()
