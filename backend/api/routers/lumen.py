# backend/api/routers/lumen.py
# Lumen-1 Self-Hosted AI Model — Inference & Status Endpoints
# Connects Flutter LumenAiService to local BYOM model (D:\ai model\lumen-1)
# මේ Router එක හරහා Voice Oracle, AI Chat, Trip Planning යන සියලු AI
# Inference calls ක්‍රියාත්මක වේ — කිසිම Commercial API Key අවශ්‍ය නැත!

from fastapi import APIRouter, HTTPException, Request, Depends
from pydantic import BaseModel
from typing import Optional
from core.database import get_db_connection
from core.auth import get_current_user
from core.rate_limit import limiter
import logging
import time
import random

router = APIRouter(prefix="/api", tags=["lumen"])
logger = logging.getLogger("LumenRouter")

# ── Request/Response Models ────────────────────────────────

class LumenInferenceRequest(BaseModel):
    prompt: str
    use_rag: bool = True
    mode: str = "default"
    system_prompt: str = ""
    temperature: float = 0.7

class LumenInferenceResponse(BaseModel):
    response: str
    model: str = "lumen-1-local"
    mode: str = "default"
    rag_used: bool = False
    processing_time_ms: float = 0.0
    knowledge_base_mode: bool = True

# ── Sri Lanka Travel Knowledge Base (Rule-Based RAG) ───────
# මේ Knowledge Base එක ඔයාගේ D:\ai model\lumen-1 Model එක
# Integrate කරන තෙක් Placeholder ලෙස ක්‍රියා කරයි.

SL_KNOWLEDGE = {
    "waterfall": "Sri Lanka has over 400 waterfalls. Notable hidden gems include Diyaluma Falls (220m, the 2nd tallest), Bambarakanda Falls (263m, the tallest), Ravana Ella Falls near Ella, and Aberdeen Falls in Nuwara Eliya district. Best visited during monsoon months (May-September for southwest, October-February for northeast).",
    "temple": "Key Buddhist temples include the Temple of the Tooth (Kandy), Dambulla Cave Temple (UNESCO), Gangaramaya (Colombo), and Ruwanwelisaya (Anuradhapura). For Hindu temples, visit Nallur Kandaswamy (Jaffna) and Munneswaram. Always remove shoes and cover shoulders before entering.",
    "beach": "Top hidden beaches include Mirissa (whale watching), Tangalle (secluded coves), Arugam Bay (surfing), Nilaveli (crystal clear), and Kalpitiya (dolphins). The south coast is best from November to April, while the east coast shines from May to September.",
    "hike": "Famous hikes include Adam's Peak (Sri Pada, 2,243m — sacred pilgrimage), Knuckles Mountain Range (UNESCO), Horton Plains (World's End viewpoint), Ella Rock, and Little Adam's Peak. Always start early morning hikes before 6 AM to avoid heat.",
    "food": "Must-try Sri Lankan dishes: Rice & Curry (the staple), Kottu Roti (chopped flatbread stir-fry), Hoppers (bowl-shaped pancakes), String Hoppers (steamed rice noodle nests), Lamprais (Dutch-Burgher rice wrapped in banana leaf), and Pol Sambol (coconut relish). Street food is generally safe in urban areas.",
    "kandy": "Kandy, the cultural capital, sits at 500m elevation around a scenic lake. Must-visit: Temple of the Tooth, Royal Botanical Gardens (Peradeniya), Kandy Lake walk, Bahiravokanda Vihara Buddha statue. The annual Esala Perahera festival (July/August) features spectacular elephant processions.",
    "ella": "Ella is a backpacker paradise in the hill country. Key attractions: Nine Arch Bridge (iconic colonial railway bridge), Little Adam's Peak (easy 45-min hike), Ella Rock (challenging 3-hour hike), Ravana Ella Falls, and the scenic train ride from Kandy to Ella (one of the world's most beautiful rail journeys).",
    "sigiriya": "Sigiriya (Lion Rock) is a UNESCO World Heritage Site — a 5th-century rock fortress built by King Kashyapa. Features mirror wall, frescoes of celestial maidens, and summit palace ruins. Best visited early morning (7 AM) to avoid crowds and heat. Combined ticket with nearby Pidurangala Rock for sunrise views.",
    "galle": "Galle Fort is a UNESCO World Heritage colonial fortress on the southwest coast. Dutch-era architecture, boutique shops, cafés, lighthouse, and ocean views. Stay inside the fort for the best atmosphere. The Literary Festival (January) is internationally renowned.",
    "budget": "Budget tips for Sri Lanka: Use local buses (cheapest transport, ~50 LKR), try PickMe/Uber for fair taxi rates, eat at local 'rice & curry' shops (200-500 LKR per meal), stay at guesthouses (2000-5000 LKR/night), carry cash for rural areas. Total daily budget: 5000-15000 LKR is comfortable.",
    "transport": "Getting around: Train (scenic, cheap — book 1st class for Kandy-Ella route), local bus (extensive network), tuk-tuk (negotiate or use PickMe app), and domestic flights (Colombo to Jaffna/Batticaloa). An International Driving Permit is needed for car rental.",
    "safety": "Sri Lanka is generally safe for tourists. Use mosquito repellent (dengue risk), drink bottled water, protect valuables in crowded areas, and be cautious with strong ocean currents (especially off-season). Emergency: Police 119, Ambulance 1990, Tourist Police 1912.",
}

def _rag_search(prompt: str) -> str:
    """Simple keyword-based RAG search against local knowledge base."""
    prompt_lower = prompt.lower()
    matches = []
    for keyword, knowledge in SL_KNOWLEDGE.items():
        if keyword in prompt_lower:
            matches.append(knowledge)
    return "\n\n".join(matches) if matches else ""

def _generate_response(prompt: str, mode: str, use_rag: bool) -> str:
    """
    Rule-based AI response generator.
    ඔයාගේ D:\\ai model\\lumen-1 Model එක Integrate කරන තෙක්
    මේ rule-based engine එක ක්‍රියා කරයි. ඉදිරියේදී මේ function එක
    replace කරන්න ඕනේ actual model inference call එකක් සමඟ.
    """
    rag_context = _rag_search(prompt) if use_rag else ""
    
    if rag_context:
        return f"🏝️ Based on our Sri Lanka travel knowledge:\n\n{rag_context}\n\n💡 Tip: For the most authentic experience, consider visiting during shoulder seasons for fewer crowds and better prices."
    
    # Mode-specific responses
    if mode == "analyst":
        return f"📊 Analysis Mode: I've reviewed your query about '{prompt[:60]}...'. Based on available data from our Sri Lanka places database, I recommend checking the Discovery screen for curated results matching your interests."
    elif mode == "security":
        return f"🛡️ Safety Advisory: Regarding '{prompt[:60]}...', Sri Lanka is generally safe for tourists. Always carry emergency contacts: Tourist Police 1912, Ambulance 1990. Use registered transport services and keep valuables secure."
    
    # Default travel assistant
    return f"🌴 Ayubowan! Thank you for your question about Sri Lanka. While I'm currently operating in knowledge-base mode, I can help you explore our curated database of hidden gems. Try asking about specific destinations like Ella, Sigiriya, Kandy, or topics like waterfalls, beaches, temples, food, or budget tips!"

# ── Endpoints ──────────────────────────────────────────────

@router.post("/test-model")
@limiter.limit("30/minute")
def lumen_inference(request: Request, req: LumenInferenceRequest, user=Depends(get_current_user)):
    """
    Lumen-1 AI Inference Endpoint.
    Flutter LumenAiService.chat() එක මේ endpoint එකට call කරනවා.
    BUG-P001: Run in worker threadpool (def instead of async def).
    """
    start_time = time.time()
    
    if not req.prompt or not req.prompt.strip():
        raise HTTPException(status_code=400, detail="Prompt cannot be empty")
    
    # BUG-P009: Do NOT log raw user prompt text to prevent PII/privacy exposure in log aggregators.
    logger.info(f"[Lumen] Inference request: mode={req.mode}, rag={req.use_rag}, prompt_len={len(req.prompt)}")
    
    try:
        response_text = _generate_response(req.prompt, req.mode, req.use_rag)
        elapsed_ms = (time.time() - start_time) * 1000
        
        return {
            "response": response_text,
            "model": "lumen-1-local",
            "mode": req.mode,
            "rag_used": req.use_rag and bool(_rag_search(req.prompt)),
            "processing_time_ms": round(elapsed_ms, 2),
            "knowledge_base_mode": True
        }
    except Exception as e:
        logger.error(f"[Lumen] Inference failed: {e}")
        raise HTTPException(status_code=503, detail="AI inference engine temporarily unavailable.")

@router.get("/status")
@limiter.limit("60/minute")
def lumen_status(request: Request):
    """
    Lumen-1 Server Status Endpoint.
    Flutter LumenAiService.isServerAlive() එක මේ endpoint එකට call කරනවා.
    """
    return {
        "status": "online",
        "model": "lumen-1-local",
        "version": "1.0.0-byom",
        "engine": "rule-based-rag",
        "rag_entries": len(SL_KNOWLEDGE),
        "supported_modes": ["default", "analyst", "optimizer", "refactor", "database", "security"],
        "note": "Running in knowledge-base mode. Connect D:\\ai model\\lumen-1 for full neural inference."
    }
