from schemas.place_schemas import PlacePublic, PlaceVerified, PlacePremium
from typing import Dict, Any, Union

def mask_place(place_data: Dict[str, Any], user_context: Dict[str, Any]) -> Union[PlacePublic, PlaceVerified, PlacePremium]:
    """
    Masks a place's data based on the user's authentication tier.
    """
    tier = user_context.get("tier", "anonymous")
    
    if tier == "anonymous":
        return PlacePublic(**place_data)
    
    if tier in ["free", "verified"]:
        return PlaceVerified(**place_data)
    
    if tier == "premium":
        return PlacePremium(**place_data)
    
    # Default to public if tier is unrecognized
    return PlacePublic(**place_data)
