import sqlite3
import os

DB_PATH = "tripme.db"
if not os.path.exists(DB_PATH):
    print(f"File not found: {DB_PATH}")
    exit(1)

conn = sqlite3.connect(DB_PATH)
cursor = conn.cursor()

print("Districts:")
cursor.execute("SELECT * FROM districts LIMIT 5")
print(cursor.fetchall())

print("\nCategories:")
cursor.execute("SELECT * FROM categories LIMIT 5")
print(cursor.fetchall())

conn.close()
