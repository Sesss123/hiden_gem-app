"""
Hidden Gems SL — AI model server (FastAPI skeleton).

This exposes the exact HTTP contract the Flutter app + Laravel backend already
expect, so connecting your trained model is just a matter of filling in the four
`# TODO: PLUG YOUR MODEL IN HERE` blocks below and pointing the app at this
server (see README.md).

Routes (all under /api, because the app's PYTHON_BACKEND_URL includes /api):
  GET  /api/status            -> health check (no auth)
  POST /api/test-model        -> Oracle chat            (x-api-key)
  POST /api/ai/plan-itinerary -> Trip Planner           (X-Admin-Internal-Key)
  POST /api/food/scan         -> Food scanner           (gzip body, no auth)
  POST /api/ai/recommendations-> optional recs proxy    (X-Admin-Internal-Key)

Run:  uvicorn main:app --host 0.0.0.0 --port 8000
"""
import base64
import gzip
import json
import os

from dotenv import load_dotenv
from fastapi import FastAPI, Header, HTTPException, Request
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field

load_dotenv()

LUMEN_API_KEY = os.getenv("LUMEN_API_KEY", "lumen_default_secure_api_key_2026")
INTERNAL_BRIDGE_KEY = os.getenv("INTERNAL_BRIDGE_KEY", "")

app = FastAPI(title="Hidden Gems SL — AI Server", version="1.0.0")


# ─────────────────────────────────────────────────────────────────────────────
# Auth helpers — reject requests whose header doesn't match the shared secret.
# ─────────────────────────────────────────────────────────────────────────────
def _require_lumen_key(x_api_key: str | None) -> None:
    if x_api_key != LUMEN_API_KEY:
        raise HTTPException(status_code=401, detail="Invalid or missing x-api-key.")


def _require_bridge_key(x_admin_internal_key: str | None) -> None:
    # Fail closed only if a bridge key is configured; if unset (local dev), allow.
    if INTERNAL_BRIDGE_KEY and x_admin_internal_key != INTERNAL_BRIDGE_KEY:
        raise HTTPException(status_code=401, detail="Invalid X-Admin-Internal-Key.")


# ─────────────────────────────────────────────────────────────────────────────
# 1. Health check — GET /api/status  (lumen_ai_service.isServerAlive)
# ─────────────────────────────────────────────────────────────────────────────
@app.get("/api/status")
async def status():
    return {"status": "ok", "model": "self-hosted", "ready": True}


# ─────────────────────────────────────────────────────────────────────────────
# 2. Oracle chat — POST /api/test-model
#    Request : {"prompt","use_rag","mode","system_prompt","temperature"}
#    Response: {"response": "<text>"}
# ─────────────────────────────────────────────────────────────────────────────
class OracleRequest(BaseModel):
    prompt: str
    use_rag: bool = True
    mode: str = "default"          # default|analyst|optimizer|refactor|database|security
    system_prompt: str = ""
    temperature: float = 0.7


@app.post("/api/test-model")
async def oracle_chat(body: OracleRequest, x_api_key: str | None = Header(default=None)):
    _require_lumen_key(x_api_key)

    # TODO: PLUG YOUR MODEL IN HERE ─────────────────────────────────────────
    # 1. (optional) if body.use_rag: retrieve top-k Sri-Lanka place records and
    #    prepend them to the prompt.
    # 2. Build the final prompt from body.system_prompt + retrieved context +
    #    body.prompt; use body.mode to switch the system persona if you want.
    # 3. Call your trained model with body.temperature.
    # answer = your_model.generate(prompt, temperature=body.temperature)
    answer = (
        "Oracle model is not wired up yet. Replace this stub in main.py "
        "(oracle_chat) with a call to your trained model."
    )
    # ────────────────────────────────────────────────────────────────────────

    # The app only reads the "response" field; on error it reads "detail".
    return {"response": answer}


# ─────────────────────────────────────────────────────────────────────────────
# 3. Trip Planner — POST /api/ai/plan-itinerary
#    (Laravel forwards the app's validated payload here.)
#    Response MUST match trip_plan_model.dart TripPlan.fromJson:
#    trip_summary (with non-empty from_city + destination_city) and a
#    non-empty itinerary list are REQUIRED — anything else throws in the app.
# ─────────────────────────────────────────────────────────────────────────────
class PlanRequest(BaseModel):
    origin: str = ""
    from_lat: float | None = None
    from_lng: float | None = None
    destination: str = ""
    days: int = 1
    start_date: str = ""
    group_type: str = ""
    pace: str = ""
    budget_lkr: float = 0
    style: str = ""
    transport_preference: str = ""
    interests: list[str] = Field(default_factory=list)
    constraints: list[str] = Field(default_factory=list)
    must_include: list[str] = Field(default_factory=list)
    avoid: list[str] = Field(default_factory=list)
    language_code: str = "en"
    user_context: dict = Field(default_factory=dict)


@app.post("/api/ai/plan-itinerary")
async def plan_itinerary(
    body: PlanRequest,
    x_admin_internal_key: str | None = Header(default=None),
):
    _require_bridge_key(x_admin_internal_key)

    # TODO: PLUG YOUR MODEL IN HERE ─────────────────────────────────────────
    # Build a real day-by-day plan. Best practice (see the AI fine-tuning plan):
    #   - RETRIEVE real matching place records (respecting budget/interests/
    #     district) and take exact lat/lng/cost_lkr FROM THE DATA — never let the
    #     model invent coordinates or prices.
    #   - Use the model for natural-language parts (day_theme, notes, human_text,
    #     safety_tip, sinhala_phrase).
    # Return the shape below. trip_summary.from_city / destination_city and a
    # non-empty itinerary are REQUIRED or the app rejects the response.
    plan = {
        "trip_summary": {
            "from_city": body.origin or "Colombo",
            "destination_city": body.destination or "Kandy",
            "days": body.days,
            "start_date": body.start_date,
            "group_type": body.group_type,
            "pace": body.pace,
            "style": body.style,
            "user_budget_lkr": body.budget_lkr,
        },
        "itinerary": [
            {
                "day": 1,
                "day_theme": "Placeholder day — wire your model into plan_itinerary()",
                "sinhala_phrase": "Ayubowan",
                "items": [
                    {
                        "time": "09:00",
                        "title": "Sample stop",
                        "type": "attraction",   # transport|attraction|food|rest|hotel|shopping|nature|culture
                        "duration_min": 90,
                        "cost_lkr": 0,
                        "lat": 7.2906,
                        "lng": 80.6337,
                        "notes": "Replace with a real retrieved place record.",
                        "ar_supported": False,
                        "eco_tip": "",
                        "etiquette": "",
                        "transport_cost_lkr": 0,
                    }
                ],
            }
        ],
        "plan_b": {"title": "Rain fallback", "reason": "Placeholder", "lat": 7.2906, "lng": 80.6337},
        "style_variants": {"compact": "", "narrative": ""},
        "safety_tip": "",
        "human_text": "This is a placeholder itinerary from the AI server skeleton.",
        "verified_score": 0,
        "kb_citations": [],
        "schema_version": 6,
        "offline_map_path": None,
        "realized_expenses": [],
    }
    # ────────────────────────────────────────────────────────────────────────
    return plan


# ─────────────────────────────────────────────────────────────────────────────
# 4. Food scanner — POST /api/food/scan
#    Body: {"image_base64": base64(gzip(bytes)), "user_mode", "spice_preference",
#           "compressed": true}. Response must be application/json (FoodModel).
# ─────────────────────────────────────────────────────────────────────────────
@app.post("/api/food/scan")
async def food_scan(request: Request):
    payload = await request.json()
    image_b64 = payload.get("image_base64", "")
    user_mode = payload.get("user_mode", "Tourist")
    spice = payload.get("spice_preference", "Medium")
    compressed = payload.get("compressed", False)

    try:
        raw = base64.b64decode(image_b64)
        image_bytes = gzip.decompress(raw) if compressed else raw
    except Exception:
        raise HTTPException(status_code=400, detail="Could not decode image payload.")

    # TODO: PLUG YOUR MODEL IN HERE ─────────────────────────────────────────
    # food = your_vision_model.identify(image_bytes, user_mode=user_mode, spice=spice)
    _ = image_bytes  # (silence unused until you wire the model)
    food = {
        "id": "placeholder",
        "name": "Unknown dish",
        "description": "Food model not wired up yet — replace this stub in food_scan().",
        "cultural_legacy": "",
        "health_benefits": [],
        "ingredients": [],
        "recipe_steps": [],
        "estimated_calories": 0,
        "protein": 0.0,
        "carbs": 0.0,
        "fat": 0.0,
        "fiber": 0.0,
        "health_rating": 0,
        "confidence": 0.0,
        "user_mode": user_mode,
        "spice_preference": spice,
    }
    # ────────────────────────────────────────────────────────────────────────
    return JSONResponse(content=food)


# ─────────────────────────────────────────────────────────────────────────────
# 5. (Optional) Recommendations — POST /api/ai/recommendations
#    Laravel also proxies this with X-Admin-Internal-Key. Wire if/when used.
# ─────────────────────────────────────────────────────────────────────────────
@app.post("/api/ai/recommendations")
async def recommendations(
    request: Request,
    x_admin_internal_key: str | None = Header(default=None),
):
    _require_bridge_key(x_admin_internal_key)
    _ = await request.json()
    # TODO: return recommendations in whatever shape the client expects.
    return {"recommendations": []}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "main:app",
        host=os.getenv("HOST", "0.0.0.0"),
        port=int(os.getenv("PORT", "8000")),
        reload=True,
    )
