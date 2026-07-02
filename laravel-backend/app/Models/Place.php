<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Place extends Model
{
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'id', 'name', 'district', 'category', 'lat', 'lng', 'rating',
        'ticket_range', 'ticket_price', 'road_type', 'road_condition', 'vehicle_access', 'risk_tags',
        'parking_range', 'parking_avail', 'best_time', 'best_time_to_visit', 'facilities',
        'description', 'province', 'opening_hours', 'mobile_signal', 'activities',
        'tourist_popularity', 'family_friendly', 'budget_category', 'toilets',
        'food_nearby', 'wheelchair_access', 'camping_allowed', 'safety_level',
        'wildlife_hazard', 'guide_required', 'rain_sensitivity', 'monsoon_note',
        'height_m', 'length_km', 'surfing',
        'ar_supported', 'ar_tier', 'ar_brand_name', 'ar_model_url', 'ar_historical_model_url',
        'ar_model_scale', 'historical_period', 'ar_file_size_mb',
        'audio_guide_url_si', 'audio_guide_url_en', 'geohash', 'image_url',
        'sync_version', 'is_deleted', 'access_tier'
    ];

    protected $casts = [
        'lat' => 'float',
        'lng' => 'float',
        'rating' => 'float',
        'ar_supported' => 'boolean',
        'ar_tier' => 'integer',
        'ar_model_scale' => 'float',
        'ar_file_size_mb' => 'float',
        'is_deleted' => 'boolean',
        'risk_tags' => 'array',
        'facilities' => 'array',
        'sync_version' => 'integer'
    ];

    public function images(): HasMany
    {
        return $this->hasMany(PlaceImage::class, 'place_id', 'id')->orderBy('sort_order');
    }

    public function coverImage()
    {
        return $this->hasOne(PlaceImage::class, 'place_id', 'id')->where('is_cover', true);
    }
}
