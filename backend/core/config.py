# backend/core/config.py
import os
from dotenv import load_dotenv

load_dotenv()

# --- Security ---
INTERNAL_BRIDGE_KEY = os.getenv("INTERNAL_API_KEY")
API_URL = os.getenv("API_URL", "http://localhost:8000")

# --- AI Models ---
CLAUDE_MODEL = "claude-3-5-sonnet-20240620"
GEMINI_FLASH = "gemini-flash-latest"
GEMINI_PRO = "gemini-pro-latest"
GPT4O_MODEL = "gpt-4o"
DEEPSEEK_MODEL = "deepseek-chat"
GROQ_MODEL = "llama-3.3-70b-versatile"

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
    critical_keys = ["ANTHROPIC_API_KEY", "GOOGLE_API_KEY_1", "INTERNAL_API_KEY"]
    missing = [k for k in critical_keys if not os.getenv(k)]
    if missing:
        print(f"⚠️  CONFIG WARNING: Missing critical environment variables: {', '.join(missing)}", flush=True)

check_environment_health()
