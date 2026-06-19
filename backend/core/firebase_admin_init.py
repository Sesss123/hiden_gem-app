# import firebase_admin # MOVED INSIDE FUNCTIONS
# from firebase_admin import credentials # MOVED INSIDE FUNCTIONS
import os
import logging
import json

logger = logging.getLogger(__name__)

def init_firebase():
    """
    Initializes Firebase Admin SDK with a prioritized multi-source approach:
    1. Local serviceAccountKey.json
    2. FIREBASE_SERVICE_ACCOUNT environment variable (JSON string or path)
    3. Application Default Credentials (ADC via gcloud/GCP)
    """
    import firebase_admin
    from firebase_admin import credentials

    if firebase_admin._apps:
        return

    # Source 1: Local File
    cred_path = os.path.join(os.getcwd(), "serviceAccountKey.json")
    
    # Source 2: Environment Variable
    env_cred = os.environ.get("FIREBASE_SERVICE_ACCOUNT")

    try:
        if os.path.exists(cred_path):
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
            logger.info("✅ Firebase Admin initialized via serviceAccountKey.json")
        
        elif env_cred:
            if env_cred.startswith("{"):
                # It's a JSON string
                cred_info = json.loads(env_cred)
                cred = credentials.Certificate(cred_info)
                firebase_admin.initialize_app(cred)
                logger.info("✅ Firebase Admin initialized via ENV JSON string")
            else:
                # It's a path
                cred = credentials.Certificate(env_cred)
                firebase_admin.initialize_app(cred)
                logger.info(f"✅ Firebase Admin initialized via ENV path: {env_cred}")
        
        else:
            # Source 3: Application Default Credentials (ADC)
            try:
                cred = credentials.ApplicationDefault()
                firebase_admin.initialize_app(cred)
                logger.info("✅ Firebase Admin initialized via Application Default Credentials (ADC)")
            except Exception:
                logger.warning("⚠️ No service account provided and ADC not available. API will run in MOCK AUTH mode.")
                
    except Exception as e:
        logger.error(f"❌ Critical error initializing Firebase Admin: {e}")

def is_firebase_initialized():
    import firebase_admin
    return len(firebase_admin._apps) > 0
