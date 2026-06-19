from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from core.database import get_db
from models.database_models import User, Subscription
from core.auth import get_current_user, verify_firebase_token
import logging
from datetime import datetime

router = APIRouter(prefix="/api/auth", tags=["auth"])
logger = logging.getLogger(__name__)

@router.post("/sync")
async def sync_user(
    token_data: dict, # Expecting {"idToken": "..."}
    db: Session = Depends(get_db)
):
    """
    Syncs the Firebase user with the local database.
    Called by the frontend immediately after Firebase login.
    """
    id_token = token_data.get("idToken")
    if not id_token:
        raise HTTPException(status_code=400, detail="Missing idToken")
    
    decoded = verify_firebase_token(id_token)
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
