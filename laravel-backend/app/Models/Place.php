<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\Builder;

class Place extends Model
{
    public const COL_ID = 'id';
    public const COL_NAME = 'name';
    public const COL_DISTRICT = 'district';
    public const COL_CATEGORY = 'category';
    public const COL_LAT = 'lat';
    public const COL_LNG = 'lng';
    public const COL_RATING = 'rating';
    public const COL_TICKET_RANGE = 'ticket_range';
    public const COL_TICKET_PRICE = 'ticket_price';
    public const COL_ROAD_TYPE = 'road_type';
    public const COL_ROAD_CONDITION = 'road_condition';
    public const COL_VEHICLE_ACCESS = 'vehicle_access';
    public const COL_RISK_TAGS = 'risk_tags';
    public const COL_PARKING_RANGE = 'parking_range';
    public const COL_PARKING_AVAIL = 'parking_avail';
    public const COL_BEST_TIME = 'best_time';
    public const COL_BEST_TIME_TO_VISIT = 'best_time_to_visit';
    public const COL_FACILITIES = 'facilities';
    public const COL_DESCRIPTION = 'description';
    public const COL_PROVINCE = 'province';
    public const COL_OPENING_HOURS = 'opening_hours';
    public const COL_MOBILE_SIGNAL = 'mobile_signal';
    public const COL_ACTIVITIES = 'activities';
    public const COL_TOURIST_POPULARITY = 'tourist_popularity';
    public const COL_FAMILY_FRIENDLY = 'family_friendly';
    public const COL_BUDGET_CATEGORY = 'budget_category';
    public const COL_TOILETS = 'toilets';
    public const COL_FOOD_NEARBY = 'food_nearby';
    public const COL_WHEELCHAIR_ACCESS = 'wheelchair_access';
    public const COL_CAMPING_ALLOWED = 'camping_allowed';
    public const COL_SAFETY_LEVEL = 'safety_level';
    public const COL_WILDLIFE_HAZARD = 'wildlife_hazard';
    public const COL_GUIDE_REQUIRED = 'guide_required';
    public const COL_RAIN_SENSITIVITY = 'rain_sensitivity';
    public const COL_MONSOON_NOTE = 'monsoon_note';
    public const COL_HEIGHT_M = 'height_m';
    public const COL_LENGTH_KM = 'length_km';
    public const COL_SURFING = 'surfing';
    public const COL_AR_SUPPORTED = 'ar_supported';
    public const COL_AR_TIER = 'ar_tier';
    public const COL_AR_BRAND_NAME = 'ar_brand_name';
    public const COL_AR_MODEL_URL = 'ar_model_url';
    public const COL_AR_HISTORICAL_MODEL_URL = 'ar_historical_model_url';
    public const COL_AR_MODEL_SCALE = 'ar_model_scale';
    public const COL_HISTORICAL_PERIOD = 'historical_period';
    public const COL_AR_FILE_SIZE_MB = 'ar_file_size_mb';
    public const COL_AUDIO_GUIDE_URL_SI = 'audio_guide_url_si';
    public const COL_AUDIO_GUIDE_URL_EN = 'audio_guide_url_en';
    public const COL_GEOHASH = 'geohash';
    public const COL_IMAGE_URL = 'image_url';
    public const COL_SYNC_VERSION = 'sync_version';
    public const COL_IS_DELETED = 'is_deleted';
    public const COL_ACCESS_TIER = 'access_tier';
    public const COL_STATUS = 'status';
    public const COL_REVIEWED_BY = 'reviewed_by';
    public const COL_REVIEW_REASON = 'review_reason';
    public const COL_CREATED_BY = 'created_by';

    public const STATUS_PENDING = 'pending';
    public const STATUS_APPROVED = 'approved';
    public const STATUS_REJECTED = 'rejected';

    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        self::COL_ID, self::COL_NAME, self::COL_DISTRICT, self::COL_CATEGORY, self::COL_LAT, self::COL_LNG, self::COL_RATING,
        self::COL_TICKET_RANGE, self::COL_TICKET_PRICE, self::COL_ROAD_TYPE, self::COL_ROAD_CONDITION, self::COL_VEHICLE_ACCESS, self::COL_RISK_TAGS,
        self::COL_PARKING_RANGE, self::COL_PARKING_AVAIL, self::COL_BEST_TIME, self::COL_BEST_TIME_TO_VISIT, self::COL_FACILITIES,
        self::COL_DESCRIPTION, self::COL_PROVINCE, self::COL_OPENING_HOURS, self::COL_MOBILE_SIGNAL, self::COL_ACTIVITIES,
        self::COL_TOURIST_POPULARITY, self::COL_FAMILY_FRIENDLY, self::COL_BUDGET_CATEGORY, self::COL_TOILETS,
        self::COL_FOOD_NEARBY, self::COL_WHEELCHAIR_ACCESS, self::COL_CAMPING_ALLOWED, self::COL_SAFETY_LEVEL,
        self::COL_WILDLIFE_HAZARD, self::COL_GUIDE_REQUIRED, self::COL_RAIN_SENSITIVITY, self::COL_MONSOON_NOTE,
        self::COL_HEIGHT_M, self::COL_LENGTH_KM, self::COL_SURFING,
        self::COL_AR_SUPPORTED, self::COL_AR_TIER, self::COL_AR_BRAND_NAME, self::COL_AR_MODEL_URL, self::COL_AR_HISTORICAL_MODEL_URL,
        self::COL_AR_MODEL_SCALE, self::COL_HISTORICAL_PERIOD, self::COL_AR_FILE_SIZE_MB,
        self::COL_AUDIO_GUIDE_URL_SI, self::COL_AUDIO_GUIDE_URL_EN, self::COL_GEOHASH, self::COL_IMAGE_URL,
        self::COL_ACCESS_TIER, self::COL_STATUS, self::COL_REVIEWED_BY, self::COL_REVIEW_REASON, self::COL_CREATED_BY
    ];

    protected $casts = [
        self::COL_LAT => 'float',
        self::COL_LNG => 'float',
        self::COL_RATING => 'float',
        self::COL_AR_SUPPORTED => 'boolean',
        self::COL_AR_TIER => 'integer',
        self::COL_AR_MODEL_SCALE => 'float',
        self::COL_AR_FILE_SIZE_MB => 'float',
        self::COL_IS_DELETED => 'boolean',
        self::COL_RISK_TAGS => 'array',
        self::COL_FACILITIES => 'array',
        self::COL_SYNC_VERSION => 'integer'
    ];

    protected static function booted()
    {
        static::addGlobalScope('active', function (Builder $builder) {
            $builder->where('is_deleted', false);
        });
    }

    public function images(): HasMany
    {
        return $this->hasMany(PlaceImage::class, 'place_id', 'id')->orderBy('sort_order');
    }

    public function coverImage(): HasOne
    {
        return $this->hasOne(PlaceImage::class, 'place_id', 'id')->where('is_cover', true);
    }

    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }
}
