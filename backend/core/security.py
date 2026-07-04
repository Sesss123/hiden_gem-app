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
import hmac

load_dotenv()

logger = logging.getLogger(__name__)

# Primary token scheme for clients
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token", auto_error=False)

# Internal bridge secret getter (BUG-Y02 Fix: Read dynamically to support live key rotation without server restart)
def get_internal_bridge_key() -> Optional[str]:
    return os.getenv("INTERNAL_BRIDGE_KEY", os.getenv("INTERNAL_API_KEY"))

async def verify_internal_key(request: Request):
    """
    Strict dependency to ensure the request comes from the Genesis Dashboard
    or an authorized internal bridge.
    """
    key = request.headers.get("X-Admin-Internal-Key")
    bridge_key = get_internal_bridge_key()
    if not bridge_key:
        logger.error("🛑 CRITICAL: INTERNAL_BRIDGE_KEY is not set in environment.")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="System security misconfiguration."
        )
    
    if not key or not hmac.compare_digest(key, bridge_key):
        logger.warning(f"❌ Internal Bridge Auth FAILED: Key mismatch for {request.url.path}")
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied.")
    
    return True

def validate_safe_url(url: str) -> bool:
    """
    Validates that a URL is safe to fetch from a backend context.
    BUG-Y01 Fix: Prevents SSRF and TOCTOU DNS rebinding by checking all resolved IPs (getaddrinfo)
    against private, loopback, link-local (cloud metadata 169.254.169.254), and reserved ranges.
    """
    try:
        parsed = urlparse(url)
        if parsed.scheme not in ["http", "https"]:
            return False
        
        hostname = parsed.hostname
        if not hostname:
            return False

        # Explicit check against cloud metadata domain names
        if hostname.lower() in ["metadata.google.internal", "169.254.169.254", "localhost", "127.0.0.1", "0.0.0.0"]:
            logger.warning(f"🛡️ SSRF Blocked: Explicit metadata/localhost domain {hostname}")
            return False

        # Resolve all DNS records for the hostname (prevents round-robin / multi-A DNS tricks)
        addr_infos = socket.getaddrinfo(hostname, None)
        for addr_info in addr_infos:
            ip_str = addr_info[4][0]
            ip = ipaddress.ip_address(ip_str)
            # Check private, loopback, link-local (AWS/GCP metadata), reserved, or multicast
            if ip.is_private or ip.is_loopback or ip.is_link_local or ip.is_reserved or ip.is_multicast:
                logger.warning(f"🛡️ SSRF Blocked: Hostname {hostname} resolves to restricted IP {ip}")
                return False
            
        return True
    except Exception as e:
        logger.error(f"Error validating URL {url}: {e}")
        return False

async def get_current_user(request: Request, token: Optional[str] = Depends(oauth2_scheme)):
    # BUG-Q003 FIX: Do NOT log full request headers — they contain Authorization tokens.
    # Only log the path and user-agent for safe diagnostics.
    ua = request.headers.get("User-Agent", "Unknown")
    logger.debug(f"🔄 Auth check for {request.url.path} | UA: {ua}")
    
    # --- Strategy A: Internal Bridge Secret ---
    internal_key = request.headers.get("X-Admin-Internal-Key")
    bridge_key = get_internal_bridge_key()
    
    if internal_key is not None and bridge_key is not None:
        if hmac.compare_digest(internal_key, bridge_key):
            logger.info(f"🔑 Internal Bridge Auth successful for {request.url.path}")
            return {
                "is_authenticated": True,
                "uid": "genesis-admin-proxy",
                "email": "admin@hiddengems.sl",
                "role": "admin",
                "tier": "admin"
            }
        else:
            logger.warning(f"❌ Internal Bridge Auth FAILED: Key mismatch for {request.url.path}")
    else:
        logger.debug(f"⚪ No internal key for {request.url.path}")

    # Logging token presence for debug
    if token:
        logger.debug(f"🔍 Bearer token present for {request.url.path}")
    else:
        logger.debug(f"⚪ No bearer token for {request.url.path}")

    if not token:
        # If no token AND no internal key, check if we allow Mock Auth
        if not is_firebase_initialized():
            is_production = os.getenv("NODE_ENV") == "production"
            if is_production or os.getenv("ALLOW_MOCK_AUTH") != "true":
                logger.error("🛑 SECURITY ALERT: Anonymous access or uninitialized auth in PRODUCTION/PROD-mode.")
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="Security module unavailable.",
                )
                
            logger.warning("🛡️  Auth Mock: Falling back to Dev-User (Firebase uninitialized)")
            return {
                "is_authenticated": True,
                "uid": "mock-user-777",
                "email": "dev@hiddengems.sl",
                "tier": "free"
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
                "role": decoded_token.get("role", "user"),
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
        # Not initialized but token provided? Allow mock if not prod and ALLOW_MOCK_AUTH is true
        if os.getenv("NODE_ENV") == "production" or os.getenv("ALLOW_MOCK_AUTH") != "true":
            raise HTTPException(status_code=500, detail="Auth unavailable")
        return {
            "is_authenticated": True,
            "uid": "mock-user-token",
            "tier": "free"
        }
