from typing import Optional
from fastapi.security import OAuth2PasswordBearer
from fastapi import Depends, HTTPException, status, Request
from core.firebase_admin_init import is_firebase_initialized
import logging
import os
import socket
from urllib.parse import urlparse
from dotenv import load_dotenv
import ipaddress

load_dotenv()

logger = logging.getLogger(__name__)

# Primary token scheme for clients
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token", auto_error=False)

# Internal bridge secret (Must be set in environment)
INTERNAL_BRIDGE_KEY = os.getenv("INTERNAL_API_KEY")

async def verify_internal_key(request: Request):
    """
    Strict dependency to ensure the request comes from the Genesis Dashboard
    or an authorized internal bridge.
    """
    key = request.headers.get("X-Admin-Internal-Key")
    if not INTERNAL_BRIDGE_KEY:
        logger.error("🛑 CRITICAL: INTERNAL_API_KEY is not set in environment.")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="System security misconfiguration."
        )
    
    if key != INTERNAL_BRIDGE_KEY:
        logger.warning(f"❌ Internal Bridge Auth FAILED: Key mismatch for {request.url.path}")
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied.")
    
    return True

def validate_safe_url(url: str) -> bool:
    """
    Validates that a URL is safe to fetch from a backend context.
    Prevents SSRF by blocking private IP ranges and localhost.
    """
    try:
        parsed = urlparse(url)
        if parsed.scheme not in ["http", "https"]:
            return False
        
        hostname = parsed.hostname
        if not hostname:
            return False

        # Resolve hostname to IP
        ip_addr = socket.gethostbyname(hostname)
        ip = ipaddress.ip_address(ip_addr)

        # Check if private or loopback
        if ip.is_private or ip.is_loopback:
            logger.warning(f"🛡️ SSRF Blocked: URL {url} resolves to private IP {ip}")
            return False
            
        return True
    except Exception as e:
        logger.error(f"Error validating URL {url}: {e}")
        return False

async def get_current_user(request: Request, token: Optional[str] = Depends(oauth2_scheme)):
    ua = request.headers.get("User-Agent", "Unknown")
    logger.warning(f"🔄 Auth attempt for {request.url.path} | UA: {ua}")
    """
    Dependency to get the current authenticated user. Supports:
    1. Internal Shared Secret (X-Admin-Internal-Key) for Dashboard Proxy
    2. Firebase ID Token (Bearer) for Client Apps
    3. Mock Auth for local development
    """
    
    # --- Strategy A: Internal Bridge Secret ---
    internal_key = request.headers.get("X-Admin-Internal-Key")
    
    # DEBUG: Log incoming headers for bridge troubleshooting
    logger.debug(f"📋 Headers for {request.url.path}: {dict(request.headers)}")
    
    if internal_key is not None:
        if internal_key == INTERNAL_BRIDGE_KEY:
            logger.warning(f"🔑 Internal Bridge Auth successful for {request.url.path}")
            return {
                "is_authenticated": True,
                "uid": "genesis-admin-proxy",
                "email": "admin@tripme.ai",
                "tier": "premium"
            }
        else:
            logger.warning(f"❌ Internal Bridge Auth FAILED: Key mismatch for {request.url.path}. Expected {INTERNAL_BRIDGE_KEY[:4]}..., got {internal_key[:4]}...")
    else:
        logger.warning(f"⚠️  Internal Bridge Header MISSING for {request.url.path}")

    # Logging token presence for debug
    if token:
        logger.warning(f"🔍 Bearer token detected for {request.url.path}")
    else:
        logger.debug(f"⚪ No bearer token for {request.url.path}")

    if not token:
        # If no token AND no internal key, check if we allow Mock Auth
        if not is_firebase_initialized():
            is_production = os.getenv("NODE_ENV") == "production"
            if is_production:
                logger.error("🛑 SECURITY ALERT: Anonymous access in PRODUCTION.")
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="Security module unavailable.",
                )
                
            logger.warning("🛡️  Auth Mock: Falling back to Dev-User (Firebase uninitialized)")
            return {
                "is_authenticated": True,
                "uid": "mock-user-777",
                "email": "dev@tripme.ai",
                "tier": "premium"
            }
            
        # Standard anonymous context
        return {
            "is_authenticated": False,
            "uid": None,
            "tier": "anonymous"
        }

    # If Firebase is initialized, we MUST verify the token
    if is_firebase_initialized():
        from firebase_admin import auth
        try:
            decoded_token = auth.verify_id_token(token)
            return {
                "is_authenticated": True,
                "uid": decoded_token.get("uid"),
                "email": decoded_token.get("email"),
                "tier": decoded_token.get("tier", "free")
            }
        except Exception as e:
            # Check for specific "kid" claim error — this is a browser-side artifact
            # (e.g. a stale Firebase custom token from the web client hitting the backend directly).
            # We must NOT throw a 401 here — that causes thrashing. Instead return anonymous
            # context and let the endpoint-level guard handle enforcement.
            err_msg = str(e)
            if 'no "kid" claim' in err_msg:
                logger.warning(f"🛡️  Residual Auth Misfire suppressed: browser-side Firebase token. Path: {request.url.path}")
                return {
                    "is_authenticated": False,
                    "uid": None,
                    "tier": "anonymous",
                    "_misfire": True
                }
            else:
                logger.error(f"Auth error: {err_msg}")
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid or expired token",
                    headers={"WWW-Authenticate": "Bearer"},
                )

    else:
        # Not initialized but token provided? Allow mock if not prod
        if os.getenv("NODE_ENV") == "production":
            raise HTTPException(status_code=500, detail="Auth unavailable")
        return {
            "is_authenticated": True,
            "uid": "mock-user-token",
            "tier": "premium"
        }
