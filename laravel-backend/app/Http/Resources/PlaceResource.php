<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class PlaceResource extends JsonResource
{
    /**
     * Transform the resource into an array for API consumers (Flutter App).
     * Includes both snake_case and camelCase keys for 100% Flutter model compatibility.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return array|\Illuminate\Contracts\Support\Arrayable|\JsonSerializable
     */
    public function toArray($request)
    {
        $imageUrl = $this->image_url;
        if ($this->relationLoaded('images') && $this->images->isNotEmpty()) {
            $cover = $this->images->firstWhere('is_cover', true) ?? $this->images->first();
            if ($cover) {
                $imageUrl = $cover->thumb_path ?: $cover->full_path;
            }
        }

        return [
            'id' => $this->id,
            'name' => $this->name,
            'description' => $this->description ?? '',
            'district' => $this->district,
            'district_id' => $this->district,
            'province' => $this->province ?? '',
            'province_id' => $this->province ?? '',
            'category' => $this->category,
            'category_id' => $this->category,
            'lat' => (float) $this->lat,
            'lng' => (float) $this->lng,
            'rating' => (float) $this->rating,
            'ticketRange' => $this->ticket_range ?? $this->ticket_price ?? 'Free',
            'ticket_price' => $this->ticket_price ?? $this->ticket_range ?? 'Free',
            'roadType' => $this->road_type ?? $this->road_condition ?? '',
            'road_condition' => $this->road_condition ?? $this->road_type ?? '',
            'vehicleAccess' => $this->vehicle_access ?? '',
            'opening_hours' => $this->opening_hours ?? '',
            'openingHours' => $this->opening_hours ?? '',
            'mobile_signal' => $this->mobile_signal ?? '',
            'activities' => $this->activities ?? '',
            'tourist_popularity' => $this->tourist_popularity ?? '',
            'family_friendly' => $this->family_friendly ?? '',
            'budget_category' => $this->budget_category ?? '',
            'budgetCategory' => $this->budget_category ?? '',
            'parking_avail' => $this->parking_avail ?? ($this->parking_range === 'Available' ? 'yes' : 'no'),
            'parkingRange' => $this->parking_range ?? '',
            'toilets' => $this->toilets ?? '',
            'food_nearby' => $this->food_nearby ?? '',
            'wheelchair_access' => $this->wheelchair_access ?? '',
            'camping_allowed' => $this->camping_allowed ?? '',
            'safety_level' => $this->safety_level ?? '',
            'safetyLevel' => $this->safety_level ?? '',
            'wildlife_hazard' => $this->wildlife_hazard ?? '',
            'guide_required' => $this->guide_required ?? '',
            'rain_sensitivity' => $this->rain_sensitivity ?? '',
            'monsoon_note' => $this->monsoon_note ?? '',
            'bestTime' => $this->best_time ?? $this->best_time_to_visit ?? '',
            'best_time_to_visit' => $this->best_time_to_visit ?? $this->best_time ?? '',
            'Height_m' => $this->height_m ?? '0',
            'height_m' => $this->height_m ?? '0',
            'Length_km' => $this->length_km ?? '0',
            'length_km' => $this->length_km ?? '0',
            'Surfing' => $this->surfing ?? 'no',
            'surfing' => $this->surfing ?? 'no',
            'riskTags' => $this->risk_tags ?? [],
            'facilities' => $this->facilities ?? [],
            'arSupported' => (bool) $this->ar_supported,
            'arTier' => (int) ($this->ar_tier ?? 3),
            'arBrandName' => $this->ar_brand_name ?? '',
            'arModelUrl' => $this->ar_model_url ?? '',
            'arHistoricalModelUrl' => $this->ar_historical_model_url ?? '',
            'arModelScale' => (float) ($this->ar_model_scale ?? 0.01),
            'historicalPeriod' => $this->historical_period ?? '',
            'ar_file_size_mb' => (float) ($this->ar_file_size_mb ?? 0),
            'audio_guide_url_si' => $this->audio_guide_url_si ?? '',
            'audio_guide_url_en' => $this->audio_guide_url_en ?? '',
            'geohash' => $this->geohash ?? '',
            'imageUrl' => $imageUrl,
            'image_url' => $imageUrl,
            'images' => $this->relationLoaded('images') ? $this->images->map(function ($img) {
                return [
                    'id' => $img->id,
                    'thumbPath' => $img->thumb_path,
                    'fullPath' => $img->full_path,
                    'isCover' => (bool) $img->is_cover,
                ];
            }) : [],
            'accessTier' => $this->access_tier ?? 'Free',
            'access_tier' => $this->access_tier ?? 'Free',
            'isPremium' => in_array($this->access_tier, ['PRO', 'VIP']),
            'sync_version' => (int) $this->sync_version,
        ];
    }
}
