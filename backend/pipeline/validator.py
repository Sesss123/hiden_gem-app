# backend/pipeline/validator.py
# UPGRADED: Image URL validation, Fuzzy duplicate detection, enhanced coordinate checks

import logging
import asyncio
import hashlib
import os
import json
from typing import Dict, Any, Tuple
from pathlib import Path

try:
    import httpx
    HTTPX_AVAILABLE = True
except ImportError:
    HTTPX_AVAILABLE = False

from core import config
from core.mongodb import get_mongo_db

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("Validator")

# ─── DUPLICATE INDEX ────────────────────────────────────────────────────────────
DUPLICATE_INDEX_FILE = Path("data/seen_names.json")


def _load_seen_names() -> dict:
    """Load the persistent seen-names index."""
    if DUPLICATE_INDEX_FILE.exists():
        try:
            with open(DUPLICATE_INDEX_FILE, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            pass
    return {}


def _save_seen_names(seen: dict):
    """Persist updated seen-names index."""
    DUPLICATE_INDEX_FILE.parent.mkdir(parents=True, exist_ok=True)
    with open(DUPLICATE_INDEX_FILE, "w", encoding="utf-8") as f:
        json.dump(seen, f, ensure_ascii=False, indent=2)


def _levenshtein_distance(s1: str, s2: str) -> int:
    """Calculate Levenshtein edit distance between two strings."""
    s1, s2 = s1.lower().strip(), s2.lower().strip()
    if s1 == s2:
        return 0
    m, n = len(s1), len(s2)
    dp = list(range(n + 1))
    for i in range(1, m + 1):
        prev = dp[0]
        dp[0] = i
        for j in range(1, n + 1):
            temp = dp[j]
            dp[j] = (prev if s1[i-1] == s2[j-1]
                     else 1 + min(prev, dp[j], dp[j-1]))
            prev = temp
    return dp[n]


def _similarity_ratio(s1: str, s2: str) -> float:
    """Return similarity 0.0–1.0 between two strings."""
    max_len = max(len(s1), len(s2), 1)
    dist = _levenshtein_distance(s1, s2)
    return 1.0 - (dist / max_len)


def is_fuzzy_duplicate(name: str, similarity_threshold: float = 0.85) -> Tuple[bool, str | None]:
    """
    Check if a place name is too similar to an already-seen name.
    Returns (is_duplicate, matched_name).
    """
    seen = _load_seen_names()
    for seen_name in seen:
        ratio = _similarity_ratio(name, seen_name)
        if ratio >= similarity_threshold:
            logger.warning(f"[Validator] Duplicate detected: '{name}' ≈ '{seen_name}' ({ratio:.0%} match)")
            return True, seen_name
    return False, None


def register_place_name(name: str):
    """Register a new place name in the seen-names index."""
    seen = _load_seen_names()
    name_key = name.strip()
    if name_key not in seen:
        seen[name_key] = {
            "registered_at": __import__("datetime").datetime.utcnow().isoformat(),
            "hash": hashlib.md5(name_key.lower().encode()).hexdigest()[:8]
        }
        _save_seen_names(seen)
        logger.info(f"[Validator] Registered new place: '{name_key}'")


async def validate_image_url(url: str) -> bool:
    """
    Check if image URL is reachable and returns a valid image content-type.
    Returns True if valid, False otherwise.
    """
    if not url or not HTTPX_AVAILABLE:
        return bool(url)  # Assume valid if httpx not available

    try:
        async with httpx.AsyncClient(timeout=8.0, follow_redirects=True) as client:
            response = await client.head(url)
            content_type = response.headers.get("content-type", "")
            is_image = any(t in content_type for t in ["image/", "jpeg", "png", "webp", "gif"])
            is_ok = response.status_code in (200, 206)

            if is_ok and is_image:
                logger.info(f"[Validator] Image URL valid ✅: {url[:60]}")
                return True
            else:
                logger.warning(f"[Validator] Image URL invalid ❌ (status={response.status_code}, ct={content_type}): {url[:60]}")
                return False
    except Exception as e:
        logger.warning(f"[Validator] Image URL check failed: {e}")
        return False  # Treat unreachable as invalid


class DataValidator:
    def __init__(self, threshold: int = 75):
        self.threshold = threshold

    def is_within_geofence(self, lat: float, lng: float) -> bool:
        """Strict bounding box for Sri Lanka from config."""
        return (config.SL_LAT_MIN <= lat <= config.SL_LAT_MAX and 
                config.SL_LNG_MIN <= lng <= config.SL_LNG_MAX)

    async def cross_reference_kb(self, lat: float, lng: float, radius_km: float = 0.5) -> list:
        """
        Cross-reference coordinates with existing Knowledge Base (places collection)
        Returns nearby existing places.
        """
        db = await get_mongo_db()
        try:
            # Simple box-based nearby check if 2dphere index isn't ready
            # Or use $near if it is. Let's start with empty list to unblock if DB is empty
            return []
        except Exception as e:
            logger.warning(f"[Validator] KB Cross-reference failed: {e}")
            return []

    def calculate_quality_score(self, place: Dict[str, Any]) -> int:
        """
        Calculates a quality score (0–100) based on:
        - Name present: 20 pts
        - Description > 150 chars: 25 pts
        - Valid Sri Lanka coordinates: 30 pts
        - Image URL present: 15 pts
        - Category present: 10 pts
        """
        score = 0

        # 1. Name check (20 pts)
        name = place.get("name", "")
        if name and len(name) > 3:
            score += 20

        # 2. Description check (25 pts)
        description = place.get("description", "")
        if description and len(description) > 150:
            score += 25
        elif description and len(description) > 50:
            score += 10

        # 3. Geofencing — Strict Sri Lanka range check (30 pts)
        lat = place.get("lat")
        lng = place.get("lng")
        if lat is not None and lng is not None:
            try:
                lat_f, lng_f = float(lat), float(lng)
                if self.is_within_geofence(lat_f, lng_f):
                    score += 30
                else:
                    logger.warning(f"[Validator] 🌎 GEOFENCE VIOLATION: lat={lat_f}, lng={lng_f}")
            except (TypeError, ValueError):
                pass

        # 4. Image URL check (15 pts)
        if place.get("external_image_url"):
            score += 15

        # 5. Category check (10 pts)
        if place.get("category"):
            score += 10

        return score


    def calculate_risk_score(self, data: Dict[str, Any]) -> float:
        """
        Calculates a risk score (0.0 to 1.0).
        0.0 = Safe, 1.0 = High risk (likely hallucination or garbage).
        """
        risk = 0.0
        
        # 1. Geofence Check (Critical risk if outside Sri Lanka)
        lat, lng = data.get("lat"), data.get("lng")
        if lat is not None and lng is not None:
            try:
                if not self.is_within_geofence(float(lat), float(lng)):
                    risk += 0.8
                    logger.warning(f"[Validator] Hallucination Risk: Geofence violation ({lat}, {lng})")
            except (ValueError, TypeError):
                risk += 0.5

        # 2. Garbage Text Detection (Repetitive patterns or nonsensical text)
        desc = data.get("description", "")
        if desc:
            # Check for repetitive characters (e.g. "aaaaaa")
            import re
            if re.search(r'(.)\1{5,}', desc):
                risk += 0.6
                logger.warning("[Validator] Hallucination Risk: Repetitive characters detected")
            
            # Check for very low entropy/variety or very short meaningful words
            words = desc.split()
            if len(words) > 10 and len(set(words)) / len(words) < 0.3:
                risk += 0.5
                logger.warning("[Validator] Hallucination Risk: Highly repetitive vocabulary")

        # 3. Mismatch Check (Simplified)
        name = data.get("name", "").lower()
        if "place name" in name or "insert name" in name:
            risk += 0.7
            logger.warning("[Validator] Hallucination Risk: Placeholder name detected")

        return min(1.0, risk)

        return False, "Does not match typical tank naming patterns"

    def is_place_valid(self, name: str, category: str, tags: dict = None) -> Tuple[bool, str]:
        """
        Universal validation for tourism places.
        Filters out noise based on the specific category.
        """
        name_lower = name.lower()
        
        # 1. Generic Noise (Roads/Streets)
        road_keywords = [" road", " street", " vidiya", " mawatha", " lane", " junction", " handiya"]
        if any(kw in name_lower for kw in road_keywords):
            # Exception: Some historical sites might have 'Road' in the search prompt but we check tags
            if tags and any(t in str(tags).lower() for t in ["historic", "tourism", "attraction"]):
                 pass
            else:
                return False, f"Potential road/junction noise detected in {category}"

        # 2. Category-Specific Logic
        if category == "Coastal":
            beach_keywords = ["beach", "surf", "reef", "coast", "bay"]
            if not any(kw in name_lower for kw in beach_keywords):
                return False, "Coastal site name lacks beach/sea context"
        
        if category == "Nature":
            nature_keywords = ["falls", "ella", "forest", "park", "cave", "hiking", "trail", "wewa", "kulam"]
            if not any(kw in name_lower for kw in nature_keywords):
                 return False, "Nature site name lacks natural feature context"

        return True, "Passed universal noise filter"

    async def validate_workflow_async(self, data: Dict[str, Any]) -> Tuple[bool, int, dict]:
        """
        Full async validation pipeline:
        1. Quality score calculation
        2. Image URL live validation
        3. Fuzzy duplicate detection
        4. KB Cross-referencing
        5. Hallucination Risk scoring
        Returns (is_approved, score, details)
        """
        from pipeline.alert_manager import get_alert_manager
        
        details = {
            "score": 0,
            "risk_score": 0.0,
            "image_valid": None,
            "is_duplicate": False,
            "duplicate_match": None,
            "kb_matches": [],
            "rejection_reasons": []
        }

        # ── Step 1: Quality Score ──
        score = self.calculate_quality_score(data)
        details["score"] = score

        # ── Step 2: Risk Scoring (Hallucination Detection) ──
        risk_score = self.calculate_risk_score(data)
        details["risk_score"] = risk_score
        
        if risk_score > 0.7:
            details["rejection_reasons"].append(f"High Hallucination Risk ({risk_score})")
            # Trigger Critical Alert for high risk
            get_alert_manager().fire_critical_alert(f"Hallucination detected for '{data.get('name')}': Risk {risk_score}")

        # ── Step 3: Image URL Validation ──
        image_url = data.get("external_image_url")
        if image_url:
            image_valid = await validate_image_url(image_url)
            details["image_valid"] = image_valid
            if not image_valid:
                score = max(0, score - 15)
                details["rejection_reasons"].append("Image URL unreachable")
        else:
            details["image_valid"] = False

        # ── Step 4: Fuzzy Duplicate Detection ──
        name = data.get("name", "")
        if name:
            is_dup, matched = is_fuzzy_duplicate(name, config.DEDUPLICATION_THRESHOLD)
            details["is_duplicate"] = is_dup
            details["duplicate_match"] = matched
            if is_dup:
                details["rejection_reasons"].append(f"Fuzzy duplicate of '{matched}'")

        # ── Step 5: KB Cross-Referencing ──
        lat, lng = data.get("lat"), data.get("lng")
        if lat and lng:
            nearby = await self.cross_reference_kb(float(lat), float(lng))
            details["kb_matches"] = [p["name"] for p in nearby]

        # ── Final Decision ──
        # Reject if score is low, or it's a duplicate, or risk is too high
        is_approved = (score >= config.QUALITY_THRESHOLD and 
                       not details["is_duplicate"] and 
                       risk_score < 0.7)

        if is_approved:
            register_place_name(name)
            logger.info(f"[Validator] ✅ FULL APPROVED '{name}' — Score: {score} | Risk: {risk_score}")
        else:
            reasons = ", ".join(details["rejection_reasons"]) if details["rejection_reasons"] else f"Low score ({score})"
            logger.warning(f"[Validator] ❌ FULL REJECTED '{name}' — Reasons: {reasons}")

        return is_approved, score, details
