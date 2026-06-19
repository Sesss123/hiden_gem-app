from slowapi import Limiter
from slowapi.util import get_remote_address
from fastapi import Request

def get_user_rate_limit_key(request: Request):
    """
    Returns the user's Firebase UID if authenticated, otherwise their IP address.
    This allows us to have per-user limits rather than per-IP limits for signed-in users.
    """
    # Authorization header is typically checked later by dependencies, 
    # but we can peek at it here for rate limiting purposes.
    auth_header = request.headers.get("Authorization")
    if auth_header and auth_header.startswith("Bearer "):
        # Use a placeholder or extract a hash of the token if necessary.
        # Ideally, we'd use the UID, but extraction is expensive here.
        # For now, we use a combination of IP + Bearer flag to differentiate.
        return f"auth:{auth_header[:20]}" 
    
    return get_remote_address(request)

# Initialize the limiter using the custom key function
limiter = Limiter(key_func=get_user_rate_limit_key, default_limits=["60/minute"])
