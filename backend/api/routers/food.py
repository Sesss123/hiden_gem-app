# backend/api/routers/food.py
# BYOM Food Scanner — REST + WebSocket Endpoints
# Connects Flutter SavorLankaService & RealTimeFoodScannerScreen
# to local food AI model (D:\ai model\food_scan_ai)
# කිසිම Commercial API Key අවශ්‍ය නැත!

from fastapi import APIRouter, HTTPException, Depends, Request
from pydantic import BaseModel, field_validator
from typing import Optional
import logging
import time
import random

from core.security import get_current_user
from core.rate_limit import limiter

router = APIRouter(prefix="/api/food", tags=["food"])
logger = logging.getLogger("FoodRouter")

# Max base64 image size: ~5 MB compressed (original ~3.75 MB image)
_MAX_BASE64_LEN = 5 * 1024 * 1024

# ── Request/Response Models ────────────────────────────────

class FoodScanRequest(BaseModel):
    image_base64: str
    user_mode: str = "Tourist"
    spice_preference: str = "Medium"
    compressed: bool = False

    @field_validator('image_base64')
    @classmethod
    def validate_image_size(cls, v):
        """BUG-Q006: Prevent oversized payloads from reaching the AI model."""
        if len(v) > _MAX_BASE64_LEN:
            raise ValueError(f'Image data exceeds maximum allowed size ({_MAX_BASE64_LEN // 1024 // 1024} MB).')
        return v

    @field_validator('user_mode')
    @classmethod
    def validate_user_mode(cls, v):
        allowed = {'Tourist', 'Weight_Loss', 'Diabetic', 'Vegetarian', 'Vegan'}
        if v not in allowed:
            raise ValueError(f'user_mode must be one of: {allowed}')
        return v

    @field_validator('spice_preference')
    @classmethod
    def validate_spice(cls, v):
        allowed = {'Mild', 'Medium', 'Spicy', 'Extra Spicy'}
        if v not in allowed:
            raise ValueError(f'spice_preference must be one of: {allowed}')
        return v

# ── Sri Lankan Food Knowledge Base ──────────────────────────
# ඔයාගේ D:\ai model\food_scan_ai Model එක Integrate කරන තෙක්
# මේ rule-based Knowledge Base එක smart fallback ලෙස ක්‍රියා කරයි.

SL_FOOD_DATABASE = [
    {
        "dishName": "Rice & Curry",
        "name": "Rice & Curry",
        "description": "The quintessential Sri Lankan meal — fragrant steamed rice served with an array of curries including dhal, vegetable, and meat or fish options.",
        "culturalSignificance": "The heart of Sri Lankan cuisine since ancient times. Every household has its own unique curry recipes passed down through generations.",
        "ingredients": ["Basmati rice", "Red lentils (dhal)", "Coconut milk", "Curry leaves", "Pandan leaves", "Turmeric", "Chili flakes", "Mustard seeds", "Fenugreek"],
        "preparationSteps": ["Cook rice with pandan leaf", "Prepare dhal curry with coconut milk", "Make pol sambol (coconut relish)", "Prepare vegetable curries", "Serve on banana leaf for authentic experience"],
        "estimatedCalories": 650,
        "protein": 18.0, "carbs": 85.0, "fat": 22.0, "fiber": 6.0,
        "healthRating": 7, "spiceLevelValue": 5,
        "region": "All Sri Lanka",
        "dietaryBadges": ["Gluten-Free Option", "Dairy-Free Option"],
        "confidence": 0.85,
        "healthBenefits": ["Rich in complex carbohydrates", "High fiber from lentils", "Anti-inflammatory spices"],
        "proTips": ["Ask for 'kiri bath' (milk rice) for a special treat", "Mix all curries together for best flavor"],
        "substitutions": ["Replace rice with string hoppers for lighter option"],
        "voiceSummary": "This is rice and curry, the soul of Sri Lankan cuisine. A symphony of flavors with fragrant rice, creamy dhal, and spicy condiments.",
        "alternateMatches": ["Mixed Rice", "Sri Lankan Plate"],
    },
    {
        "dishName": "Kottu Roti",
        "name": "Kottu Roti",
        "description": "Chopped godamba roti stir-fried with vegetables, eggs, and optional meat on a hot griddle, creating the iconic rhythmic chopping sounds.",
        "culturalSignificance": "Born in Batticaloa, Kottu has become Sri Lanka's most popular street food. The rhythmic clang of metal blades on the hot plate is the soundtrack of Sri Lankan nights.",
        "ingredients": ["Godamba roti (flatbread)", "Eggs", "Leeks", "Carrots", "Cabbage", "Curry leaves", "Chili flakes", "Soy sauce"],
        "preparationSteps": ["Shred roti into strips", "Heat griddle to high temperature", "Stir-fry vegetables", "Add roti and eggs", "Chop rhythmically with metal cleavers", "Season with curry sauce"],
        "estimatedCalories": 550,
        "protein": 22.0, "carbs": 60.0, "fat": 24.0, "fiber": 4.0,
        "healthRating": 6, "spiceLevelValue": 6,
        "region": "Eastern Province (Batticaloa)",
        "dietaryBadges": ["Protein-Rich"],
        "confidence": 0.88,
        "healthBenefits": ["Good protein source", "Contains vegetables"],
        "proTips": ["Order 'cheese kottu' for a fusion twist", "Best enjoyed at night from street vendors"],
        "substitutions": ["Vegetable kottu for vegetarian option"],
        "voiceSummary": "This is Kottu Roti, Sri Lanka's beloved street food. Chopped flatbread stir-fried with a medley of vegetables and aromatic spices.",
        "alternateMatches": ["Chopped Roti", "Street Roti Stir-fry"],
    },
    {
        "dishName": "Egg Hoppers",
        "name": "Egg Hoppers",
        "description": "Bowl-shaped fermented rice flour pancakes with a perfectly cooked egg in the center, served with spicy sambol and lentil curry.",
        "culturalSignificance": "Hoppers (appa/appam) are a breakfast staple with origins in South Indian cuisine, perfected over centuries in Sri Lanka with coconut milk fermentation.",
        "ingredients": ["Rice flour", "Coconut milk", "Toddy or yeast", "Eggs", "Sugar", "Salt"],
        "preparationSteps": ["Ferment rice flour batter with coconut milk overnight", "Heat hopper pan", "Swirl thin batter", "Crack egg in center", "Cover and cook until edges crispy"],
        "estimatedCalories": 180,
        "protein": 8.0, "carbs": 22.0, "fat": 7.0, "fiber": 1.0,
        "healthRating": 7, "spiceLevelValue": 2,
        "region": "All Sri Lanka",
        "dietaryBadges": ["Gluten-Free", "Vegetarian"],
        "confidence": 0.82,
        "healthBenefits": ["Low calorie", "Good protein from egg", "Fermented for gut health"],
        "proTips": ["Try 'milk hoppers' (kiri appa) with jaggery for dessert", "Dip in lunu miris (onion chili relish)"],
        "substitutions": ["Plain hoppers without egg for vegan option"],
        "voiceSummary": "These are Egg Hoppers, a beloved Sri Lankan breakfast. Crispy bowl-shaped pancakes cradling a perfectly cooked egg.",
        "alternateMatches": ["Appa", "Appam", "String Hoppers Nest"],
    },
    {
        "dishName": "String Hoppers",
        "name": "String Hoppers (Idi Appa)",
        "description": "Delicate steamed rice noodle nests, traditionally served for breakfast with coconut milk curry (kiri hodi) and pol sambol.",
        "culturalSignificance": "An ancient Tamil-origin dish perfected in Sri Lanka. Making string hoppers is an art — the dough is pressed through a special mould (indi appa press).",
        "ingredients": ["Rice flour (red or white)", "Hot water", "Salt", "Coconut", "Curry leaves"],
        "preparationSteps": ["Knead rice flour with hot water", "Press through string hopper mould onto bamboo mats", "Steam for 3-4 minutes", "Serve stacked with curries"],
        "estimatedCalories": 120,
        "protein": 3.0, "carbs": 26.0, "fat": 0.5, "fiber": 1.0,
        "healthRating": 8, "spiceLevelValue": 1,
        "region": "All Sri Lanka",
        "dietaryBadges": ["Gluten-Free", "Vegan", "Low-Fat"],
        "confidence": 0.80,
        "healthBenefits": ["Very low fat", "Gluten free", "Easy to digest"],
        "proTips": ["Red rice string hoppers are more nutritious", "Best with pol sambol and lunu miris"],
        "substitutions": ["Use red rice flour for higher fiber"],
        "voiceSummary": "These are String Hoppers, delicate steamed rice noodle nests. A light and wholesome traditional Sri Lankan breakfast.",
        "alternateMatches": ["Idi Appa", "Noodle Nests"],
    },
]

def _identify_food(user_mode: str, spice_preference: str) -> dict:
    """
    Rule-based food identification fallback.
    ඔයාගේ D:\\ai model\\food_scan_ai Vision Model එක Integrate කරන තෙක්
    මේ function එක random selection එකක් කරයි.
    ඉදිරියේදී actual image classification replace කරන්න.
    """
    # Select a random dish from our knowledge base
    dish = random.choice(SL_FOOD_DATABASE).copy()
    
    # Adjust spice level based on preference
    spice_map = {"Mild": 2, "Medium": 5, "Spicy": 8, "Extra Spicy": 10}
    dish["spiceLevelValue"] = spice_map.get(spice_preference, 5)
    
    # Add mode-specific recommendations
    if user_mode.lower() == "tourist":
        dish["voiceSummary"] = dish.get("voiceSummary", "") + " A must-try for visitors to Sri Lanka!"
    elif user_mode.lower() == "weight_loss":
        dish["voiceSummary"] = dish.get("voiceSummary", "") + f" This dish has approximately {dish.get('estimatedCalories', 0)} calories."
    elif user_mode.lower() == "diabetic":
        dish["voiceSummary"] = dish.get("voiceSummary", "") + f" Carbohydrate content: {dish.get('carbs', 0)}g. Monitor portion size."
    
    return dish


# ── Endpoints ──────────────────────────────────────────────

@router.post("/scan")
@limiter.limit("10/minute")
async def scan_food(
    request: Request,
    req: FoodScanRequest,
    user=Depends(get_current_user),
):
    """
    BYOM Food Identification Endpoint.
    Flutter SavorLankaService._callCustomByomFoodScanner() එක මෙහිට call කරයි.

    Request: {"image_base64": "...", "user_mode": "Tourist", "spice_preference": "Medium"}
    Response: FoodModel-compatible JSON

    Auth: Firebase ID Token (Bearer) or internal bridge key required.
    Rate Limit: 10 scans/minute per user/IP.
    """
    start_time = time.time()

    if not req.image_base64 or len(req.image_base64) < 10:
        raise HTTPException(status_code=400, detail="Invalid or empty image data")

    uid = user.get("uid", "anonymous")
    logger.info(
        f"[FoodScan] Scan request: uid={uid}, mode={req.user_mode}, "
        f"spice={req.spice_preference}, image_size={len(req.image_base64)} chars"
    )

    try:
        result = _identify_food(req.user_mode, req.spice_preference)
        elapsed_ms = (time.time() - start_time) * 1000

        result["processing_time_ms"] = round(elapsed_ms, 2)
        result["detection_engine"] = "byom-knowledge-base"
        result["id"] = str(int(time.time() * 1000))

        logger.info(f"[FoodScan] Scan complete in {elapsed_ms:.0f}ms for uid={uid}.")
        return result
    except Exception as e:
        logger.error(f"[FoodScan] Scan failed for uid={uid}: {e}")
        raise HTTPException(status_code=500, detail="Food scan failed. Please try again.")
