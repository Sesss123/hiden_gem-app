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
                $path = $cover->thumb_path ?: $cover->full_path;
                $imageUrl = str_starts_with($path, 'http') ? $path : asset('storage/' . ltrim($path, '/'));
            }
        } elseif ($imageUrl && !str_starts_with($imageUrl, 'http')) {
            $imageUrl = asset('storage/' . ltrim($imageUrl, '/'));
        }

        return [
            'id' => $this->id,
            'name' => $this->name,
            'description' => $this->description ?? '',
            'district' => $this->district,
            'province' => $this->province ?? '',
            'category' => $this->category,
            'lat' => (float) $this->lat,
            'lng' => (float) $this->lng,
            'rating' => (float) $this->rating,
            'ticket_range' => $this->ticket_range ?? $this->ticket_price ?? 'Free',
            'ticketRange' => $this->ticket_range ?? $this->ticket_price ?? 'Free',
            'road_type' => $this->road_type ?? $this->road_condition ?? '',
            'roadType' => $this->road_type ?? $this->road_condition ?? '',
            'vehicle_access' => $this->vehicle_access ?? '',
            'vehicleAccess' => $this->vehicle_access ?? '',
            'opening_hours' => $this->opening_hours ?? '',
            'mobile_signal' => $this->mobile_signal ?? '',
            'activities' => $this->activities ?? '',
            'tourist_popularity' => $this->tourist_popularity ?? '',
            'family_friendly' => $this->family_friendly ?? '',
            'budget_category' => $this->budget_category ?? '',
            'parking_avail' => $this->parking_avail ?? ($this->parking_range === 'Available' ? 'yes' : 'no'),
            'parking_range' => $this->parking_range ?? '',
            'parkingRange' => $this->parking_range ?? '',
            'toilets' => $this->toilets ?? '',
            'food_nearby' => $this->food_nearby ?? '',
            'wheelchair_access' => $this->wheelchair_access ?? '',
            'camping_allowed' => $this->camping_allowed ?? '',
            'safety_level' => $this->safety_level ?? '',
            'wildlife_hazard' => $this->wildlife_hazard ?? '',
            'guide_required' => $this->guide_required ?? '',
            'rain_sensitivity' => $this->rain_sensitivity ?? '',
            'monsoon_note' => $this->monsoon_note ?? '',
            'best_time' => $this->best_time ?? $this->best_time_to_visit ?? '',
            'bestTime' => $this->best_time ?? $this->best_time_to_visit ?? '',
            'height_m' => $this->height_m ?? '0',
            'length_km' => $this->length_km ?? '0',
            'surfing' => $this->surfing ?? 'no',
            'risk_tags' => $this->risk_tags ?? [],
            'riskTags' => $this->risk_tags ?? [],
            'facilities' => $this->facilities ?? [],
            'ar_supported' => (bool) $this->ar_supported,
            'arSupported' => (bool) $this->ar_supported,
            'ar_tier' => (int) ($this->ar_tier ?? 3),
            'arTier' => (int) ($this->ar_tier ?? 3),
            'ar_brand_name' => $this->ar_brand_name ?? '',
            'arBrandName' => $this->ar_brand_name ?? '',
            'ar_model_url' => $this->ar_model_url ?? '',
            'arModelUrl' => $this->ar_model_url ?? '',
            'ar_historical_model_url' => $this->ar_historical_model_url ?? '',
            'arHistoricalModelUrl' => $this->ar_historical_model_url ?? '',
            'ar_model_scale' => (float) ($this->ar_model_scale ?? 0.01),
            'arModelScale' => (float) ($this->ar_model_scale ?? 0.01),
            'historical_period' => $this->historical_period ?? '',
            'historicalPeriod' => $this->historical_period ?? '',
            'ar_file_size_mb' => (float) ($this->ar_file_size_mb ?? 0),
            'audio_guide_url_si' => $this->audio_guide_url_si ?? '',
            'audio_guide_url_en' => $this->audio_guide_url_en ?? '',
            'geohash' => $this->geohash ?? '',
            'image_url' => $imageUrl,
            'imageUrl' => $imageUrl,
            'images' => $this->relationLoaded('images') ? $this->images->map(function ($img) {
                return [
                    'id' => $img->id,
                    'thumb_path' => str_starts_with($img->thumb_path, 'http') ? $img->thumb_path : asset('storage/' . ltrim($img->thumb_path, '/')),
                    'thumbPath' => str_starts_with($img->thumb_path, 'http') ? $img->thumb_path : asset('storage/' . ltrim($img->thumb_path, '/')),
                    'full_path' => str_starts_with($img->full_path, 'http') ? $img->full_path : asset('storage/' . ltrim($img->full_path, '/')),
                    'fullPath' => str_starts_with($img->full_path, 'http') ? $img->full_path : asset('storage/' . ltrim($img->full_path, '/')),
                    'is_cover' => (bool) $img->is_cover,
                    'isCover' => (bool) $img->is_cover,
                ];
            }) : [],
            'access_tier' => $this->access_tier ?? 'Free',
            'accessTier' => $this->access_tier ?? 'Free',
            'isPremium' => in_array($this->access_tier, ['PRO', 'VIP']),
            'sync_version' => (int) $this->sync_version,
        ];
    }
}
