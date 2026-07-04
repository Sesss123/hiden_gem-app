import logging
import os
from fastapi import HTTPException, Depends, Security
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from firebase_admin import auth
from sqlalchemy.orm import Session
from core.database import get_db
from models.database_models import User

import re

# Strict validation patterns to prevent injection payloads
JWT_PATTERN = re.compile(r'^[a-zA-Z0-9_\-\.]+$')
UID_PATTERN = re.compile(r'^[a-zA-Z0-9_\-]+$')

logger = logging.getLogger(__name__)
security = HTTPBearer()

def is_safe_token(token: str) -> bool:
    if token == "MOCK_TOKEN":
        return True
    return bool(JWT_PATTERN.match(token))

class MockAuthService:
    @staticmethod
    def verify_mock_token(id_token: str) -> dict:
        if os.getenv("NODE_ENV") != "production" and os.getenv("ALLOW_MOCK_AUTH") == "true":
            return {"uid": "mock-user-123", "email": "mock@hiddengems.sl", "tier": "free"}
        raise HTTPException(status_code=401, detail="Mock authentication disabled in production.")

class FirebaseAuthService:
    @staticmethod
    def verify_token(id_token: str) -> dict:
        if not id_token or not is_safe_token(id_token):
            raise HTTPException(
                status_code=400,
                detail="Malformed or unsafe token format."
            )

        if id_token == "MOCK_TOKEN":
            return MockAuthService.verify_mock_token(id_token)

        # BUG-101 / BUG-121 / BUG-141: Validate signature format and hash algorithm (RS256)
        try:
            import base64
            import json
            parts = id_token.split('.')
            if len(parts) != 3:
                raise HTTPException(status_code=401, detail="Invalid token structure.")
            
            header_segment = parts[0]
            padded = header_segment + '=' * (4 - len(header_segment) % 4)
            header_data = json.loads(base64.urlsafe_b64decode(padded).decode('utf-8'))
            if header_data.get("alg") != "RS256":
                raise HTTPException(status_code=401, detail="Unsupported signature format or hash algorithm.")
        except Exception as e:
            if isinstance(e, HTTPException):
                raise e
            raise HTTPException(status_code=401, detail="Malformed token header.")

        try:
            # Check revoked to verify against latest key signatures
            decoded_token = auth.verify_id_token(id_token, check_revoked=True)

            # BUG-081: Enforce token expiration validation on decoded signatures
            import time
            exp = decoded_token.get("exp")
            if exp and exp < time.time():
                raise HTTPException(status_code=401, detail="Token has expired.")

            # BUG-121 / BUG-141: Validate authentication targets (issuer and audience format)
            iss = decoded_token.get("iss", "")
            aud = decoded_token.get("aud", "")
            if not iss.startswith("https://securetoken.google.com/"):
                raise HTTPException(status_code=401, detail="Authentication target mismatch (invalid issuer).")
            if not aud or len(aud) == 0:
                raise HTTPException(status_code=401, detail="Authentication target mismatch (invalid audience).")

            return decoded_token
        except Exception as e:
            if isinstance(e, HTTPException):
                raise e
            logger.error(f"Error verifying Firebase token: {e}")
            raise HTTPException(
                status_code=401,
                detail=f"Invalid authentication credentials: {str(e)}"
            )

def verify_firebase_token(id_token: str):
    """
    Verifies the Firebase ID token and returns decoded claims.
    Delegates to FirebaseAuthService and MockAuthService.
    """
    return FirebaseAuthService.verify_token(id_token)

# Rate limiter for auto-creations (max 20 per minute globally to prevent DoS)
_creation_timestamps = []

def get_current_user(
    res: HTTPAuthorizationCredentials = Security(security),
    db: Session = Depends(get_db)
) -> User:
    """
    FastAPI dependency that extracts the user from the Bearer token.
    Ensures the user exists in the local database.
    Runs synchronously in threadpool to prevent blocking FastAPI main event loop.
    """
    token = res.credentials
    decoded = verify_firebase_token(token)
    uid = decoded.get("uid")
    
    if not uid or not UID_PATTERN.match(uid):
        raise HTTPException(
            status_code=400,
            detail="Invalid user identification format."
        )
    
    # Check if user exists in local DB
    user = db.query(User).filter(User.firebase_uid == uid).first()
    
    if not user:
        import time
        now = time.time()
        global _creation_timestamps
        _creation_timestamps = [t for t in _creation_timestamps if now - t < 60]
        if len(_creation_timestamps) >= 20:
            raise HTTPException(status_code=429, detail="User creation rate limit exceeded. Please try again later.")
        _creation_timestamps.append(now)

        raw_email = decoded.get("email", "unknown@example.com")
        # Sanitize email string to remove any script tags or special injection chars
        clean_email = re.sub(r'[^\w\.\-\+@]', '', raw_email)
        # This shouldn't normally happen if /api/auth/sync is called first,
        # but we can auto-create as a safety measure.
        user = User(
            firebase_uid=uid,
            email=clean_email,
            tier="free"
        )
        db.add(user)
        db.commit()
        db.refresh(user)
    
    return user

def admin_only(current_user: User = Depends(get_current_user)):
    """
    Dependency to restrict routes to admin users only.
    """
    if current_user.tier != "admin":
        raise HTTPException(
            status_code=403,
            detail="Forbidden: Admin access only"
        )
    return current_user
