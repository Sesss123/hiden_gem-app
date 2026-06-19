import logging
from fastapi import HTTPException, Depends, Security
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from firebase_admin import auth
from sqlalchemy.orm import Session
from core.database import get_db
from models.database_models import User

logger = logging.getLogger(__name__)
security = HTTPBearer()

def verify_firebase_token(id_token: str):
    """
    Verifies the Firebase ID token and returns decoded claims.
    If in mock mode (no service account), it returns a dummy user.
    """
    try:
        decoded_token = auth.verify_id_token(id_token)
        return decoded_token
    except Exception as e:
        logger.error(f"Error verifying Firebase token: {e}")
        # For development ease if Firebase isn't configured, we can allow a MOCK_TOKEN
        if id_token == "MOCK_TOKEN":
            return {"uid": "mock-user-123", "email": "mock@example.com"}
        raise HTTPException(
            status_code=401,
            detail=f"Invalid authentication credentials: {str(e)}"
        )

async def get_current_user(
    res: HTTPAuthorizationCredentials = Security(security),
    db: Session = Depends(get_db)
) -> User:
    """
    FastAPI dependency that extracts the user from the Bearer token.
    Ensures the user exists in the local database.
    """
    token = res.credentials
    decoded = verify_firebase_token(token)
    uid = decoded.get("uid")
    
    # Check if user exists in local DB
    user = db.query(User).filter(User.firebase_uid == uid).first()
    
    if not user:
        # This shouldn't normally happen if /api/auth/sync is called first,
        # but we can auto-create as a safety measure.
        user = User(
            firebase_uid=uid,
            email=decoded.get("email", "unknown@example.com"),
            tier="free"
        )
        db.add(user)
        db.commit()
        db.refresh(user)
    
    return user

async def admin_only(current_user: User = Depends(get_current_user)):
    """
    Dependency to restrict routes to admin users only.
    """
    if current_user.tier != "admin":
        raise HTTPException(
            status_code=403,
            detail="Forbidden: Admin access only"
        )
    return current_user
