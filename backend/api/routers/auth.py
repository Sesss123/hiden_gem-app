from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session
from core.database import get_db
from models.database_models import User, Subscription
from core.auth import get_current_user, verify_firebase_token
import logging
from datetime import datetime, timedelta
from collections import defaultdict
import threading

router = APIRouter(prefix="/api/auth", tags=["auth"])
logger = logging.getLogger(__name__)

# BUG-061: Simple in-memory brute-force protection (per IP, 5 attempts / 15 min window)
_failed_logins: dict = defaultdict(list)
_login_lock = threading.Lock()
_MAX_ATTEMPTS = 5
_WINDOW_MINUTES = 15

def _check_rate_limit(ip: str):
    """Raises HTTP 429 if the IP exceeded failed login attempts in the sliding window."""
    now = datetime.utcnow()
    cutoff = now - timedelta(minutes=_WINDOW_MINUTES)
    with _login_lock:
        # Prune old attempts
        _failed_logins[ip] = [t for t in _failed_logins[ip] if t > cutoff]
        if len(_failed_logins[ip]) >= _MAX_ATTEMPTS:
            raise HTTPException(
                status_code=429,
                detail=f"Too many failed login attempts. Please wait {_WINDOW_MINUTES} minutes."
            )

def _record_failure(ip: str):
    """Records a failed login attempt for the given IP."""
    with _login_lock:
        _failed_logins[ip].append(datetime.utcnow())

def _clear_failures(ip: str):
    """Clears failed attempts after a successful login."""
    with _login_lock:
        _failed_logins.pop(ip, None)

@router.post("/sync")
async def sync_user(
    request: Request,
    token_data: dict, # Expecting {"idToken": "..."}
    db: Session = Depends(get_db)
):
    """
    Syncs the Firebase user with the local database.
    Called by the frontend immediately after Firebase login.
    """
    client_ip = request.client.host if request.client else "unknown"

    # BUG-061: Check rate limit before processing credentials
    _check_rate_limit(client_ip)

    id_token = token_data.get("idToken")
    if not id_token:
        raise HTTPException(status_code=400, detail="Missing idToken")
    
    decoded = verify_firebase_token(id_token)
    if not decoded:
        # BUG-061: Record failure on bad token
        _record_failure(client_ip)
        raise HTTPException(status_code=401, detail="Invalid or expired token")
    uid = decoded.get("uid")
    email = decoded.get("email")
    
    # Check if user exists
    user = db.query(User).filter(User.firebase_uid == uid).first()
    
    if not user:
        # Create new user
        user = User(
            firebase_uid=uid,
            email=email,
            tier="free",
            created_at=datetime.utcnow()
        )
        db.add(user)
        db.commit()
        db.refresh(user)
        logger.info(f"Created new user record for {email}")
    else:
        # Update email if changed
        if email and user.email != email:
            user.email = email
            db.commit()
            db.refresh(user)

    # BUG-061: Clear failed-login history on success
    _clear_failures(client_ip)

    # Get active subscription if any
    active_sub = db.query(Subscription).filter(
        Subscription.user_id == user.id,
        Subscription.status == 'active'
    ).first()

    return {
        "id": user.id,
        "email": user.email,
        "tier": user.tier,
        "subscription": {
            "status": active_sub.status if active_sub else "none",
            "expires_at": active_sub.expires_at if active_sub else None
        } if active_sub else None
    }

@router.get("/me")
async def get_me(current_user: User = Depends(get_current_user)):
    """
    Returns the current logged-in user's profile.
    """
    return {
        "id": current_user.id,
        "email": current_user.email,
        "tier": current_user.tier,
        "firebase_uid": current_user.firebase_uid
    }
