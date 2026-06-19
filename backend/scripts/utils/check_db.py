import sqlite3
import json

conn = sqlite3.connect('tripme.db')
cur = conn.cursor()
cur.execute("PRAGMA table_info(places)")
cols = [row[1] for row in cur.fetchall()]
print(f"Columns: {cols}")

cur.execute("SELECT * FROM places LIMIT 1")
row = cur.fetchone()
if row:
    print("Row data found.")
else:
    print("No data in places table.")
conn.close()
