import hashlib
from slowapi import Limiter
from slowapi.util import get_remote_address
from fastapi import Request

def get_user_rate_limit_key(request: Request):
    """
    Returns a SHA-256 hash of the Bearer token if authenticated, otherwise the IP address.
    This ensures each user token gets a unique, secure rate limit bucket.
    """
    auth_header = request.headers.get("Authorization")
    if auth_header and auth_header.startswith("Bearer "):
        token = auth_header[7:]
        token_hash = hashlib.sha256(token.encode('utf-8')).hexdigest()
        return f"auth:{token_hash}"
    
    return get_remote_address(request)

# Initialize the limiter using the custom key function
limiter = Limiter(key_func=get_user_rate_limit_key, default_limits=["60/minute"])
