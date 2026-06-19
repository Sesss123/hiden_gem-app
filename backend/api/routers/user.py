from fastapi import APIRouter, Depends, HTTPException
from core.security import get_current_user
from core.database import get_db_connection
from typing import List
import uuid
from datetime import datetime

router = APIRouter(prefix="/api/user", tags=["user"])

@router.get("/profile")
async def get_user_profile(user=Depends(get_current_user)):
    """Returns the user profile with tier and activity summary."""
    conn = get_db_connection()
    cur = conn.cursor()
    try:
        # Count favorites
        cur.execute("SELECT COUNT(*) FROM user_favorites WHERE user_id = ?", (user["id"],))
        fav_count = cur.fetchone()[0]
        
        # Count history
        cur.execute("SELECT COUNT(*) FROM user_history WHERE user_id = ?", (user["id"],))
        history_count = cur.fetchone()[0]
        
        return {
            "email": user["email"],
            "tier": user["tier"],
            "stats": {
                "favorites": fav_count,
                "visited": history_count
            }
        }
    finally:
        conn.close()

@router.get("/favorites")
async def get_favorites(user=Depends(get_current_user)):
    """Retrieve the user's saved hidden gems."""
    conn = get_db_connection()
    cur = conn.cursor()
    try:
        cur.execute("""
            SELECT p.*, (SELECT image_path FROM place_images WHERE place_id = p.id AND is_cover = 1 LIMIT 1) as thumbnail
            FROM user_favorites f
            JOIN places p ON f.place_id = p.id
            WHERE f.user_id = ?
        """, (user["id"],))
        rows = cur.fetchall()
        return [dict(row) for row in rows]
    finally:
        conn.close()

@router.post("/favorites/{place_id}")
async def toggle_favorite(place_id: str, user=Depends(get_current_user)):
    """Add or remove a place from favorites."""
    conn = get_db_connection()
    cur = conn.cursor()
    try:
        cur.execute("SELECT id FROM user_favorites WHERE user_id = ? AND place_id = ?", (user["id"], place_id))
        existing = cur.fetchone()
        
        if existing:
            cur.execute("DELETE FROM user_favorites WHERE id = ?", (existing["id"],))
            message = "Removed from favorites"
            active = False
        else:
            fid = str(uuid.uuid4())
            now = datetime.now().isoformat()
            cur.execute("INSERT INTO user_favorites (id, user_id, place_id, created_at) VALUES (?, ?, ?, ?)", 
                        (fid, user["id"], place_id, now))
            message = "Added to favorites"
            active = True
            
        conn.commit()
        return {"message": message, "active": active}
    finally:
        conn.close()

@router.post("/history/{place_id}")
async def log_visit(place_id: str, notes: str = "", user=Depends(get_current_user)):
    """Record a visit to a hidden gem."""
    conn = get_db_connection()
    cur = conn.cursor()
    try:
        hid = str(uuid.uuid4())
        now = datetime.now().isoformat()
        cur.execute("INSERT INTO user_history (id, user_id, place_id, visited_at, notes) VALUES (?, ?, ?, ?, ?)", 
                    (hid, user["id"], place_id, now, notes))
        conn.commit()
        return {"message": "Visit logged"}
    finally:
        conn.close()
