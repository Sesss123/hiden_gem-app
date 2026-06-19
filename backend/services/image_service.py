import os
import uuid
import shutil
from PIL import Image
from fastapi import UploadFile

UPLOAD_DIR = "uploads"
THUMB_DIR = os.path.join(UPLOAD_DIR, "thumbnails")
os.makedirs(THUMB_DIR, exist_ok=True)

def get_absolute_url(rel_path: str, base_url: str = None) -> str:
    """Converts a relative path to an absolute URL."""
    if not rel_path: return ""
    if rel_path.startswith("http"): return rel_path
    
    # Standardize path separators
    rel_path = rel_path.replace("\\", "/")
    
    if base_url:
        return f"{base_url.rstrip('/')}/{rel_path.lstrip('/')}"
    
    # Fallback to local env if base_url is not provided
    api_url = os.getenv("API_URL", "http://localhost:8000")
    return f"{api_url.rstrip('/')}/{rel_path.lstrip('/')}"

def process_image(file: UploadFile, place_id: str, index: int):
    # original path
    ext = os.path.splitext(file.filename)[1]
    filename = f"{place_id}_{index}{ext}"
    rel_path = os.path.join(UPLOAD_DIR, filename)
    abs_path = os.path.join(os.getcwd(), rel_path)
    
    with open(abs_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
    
    # thumbnail
    thumb_filename = f"{place_id}_{index}_thumb.jpg"
    thumb_rel = os.path.join("uploads", "thumbnails", thumb_filename)
    thumb_abs = os.path.join(os.getcwd(), thumb_rel)
    
    try:
        with Image.open(abs_path) as img:
            img.convert('RGB').save(thumb_abs, "JPEG", quality=80, optimize=True)
    except:
        thumb_rel = rel_path # fallback
        
    # Return absolute URLs as well
    full_url = get_absolute_url(rel_path)
    thumb_url = get_absolute_url(thumb_rel)
    
    return {
        "rel_path": rel_path,
        "thumb_rel": thumb_rel,
        "full_url": full_url,
        "thumb_url": thumb_url
    }
