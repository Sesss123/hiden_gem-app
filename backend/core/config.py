# backend/core/config.py
import os
import logging
from dotenv import load_dotenv

load_dotenv()
logger = logging.getLogger("Config")

# --- Security ---
INTERNAL_BRIDGE_KEY = os.getenv("INTERNAL_BRIDGE_KEY", os.getenv("INTERNAL_API_KEY"))
API_URL = os.getenv("API_URL", "http://localhost:8000")

# --- AI Models ---
GEMINI_FLASH = "gemini-flash-latest"
GEMINI_PRO = "gemini-pro-latest"

DEFAULT_TEMPERATURE = 0.1
MAX_EXTRACTION_TOKENS = 2048

# --- Validation & Geofencing ---
# Sri Lanka Bounding Box
SL_LAT_MIN = 5.72
SL_LAT_MAX = 9.85
SL_LNG_MIN = 79.52
SL_LNG_MAX = 81.88

QUALITY_THRESHOLD = 75

# --- Pipeline Performance ---
MAX_CONCURRENT_EXTRACTIONS = 15
CACHE_EXPIRY_DAYS = 7
DEDUPLICATION_THRESHOLD = 0.85  # Levenshtein ratio

# --- Reliability Check ---
def check_environment_health():
    # 🏛️ Modified for Self-Hosted BYOM Architecture: No external commercial AI keys required
    critical_keys = ["INTERNAL_API_KEY"]
    missing = [k for k in critical_keys if not os.getenv(k)]
    if missing:
        logger.warning(f"⚠️  CONFIG WARNING: Missing critical internal bridge key: {', '.join(missing)}")

check_environment_health()
