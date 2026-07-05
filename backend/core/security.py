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


