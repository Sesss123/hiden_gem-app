<?php

namespace App\Http\Resources;

use App\Http\Resources\Concerns\BuildsPublicStorageUrl;
use Illuminate\Http\Resources\Json\JsonResource;

class PlaceResource extends JsonResource
{
    use BuildsPublicStorageUrl;

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
                $imageUrl = $this->toPublicUrl($path);
            }
        } elseif ($imageUrl && !str_starts_with($imageUrl, 'http')) {
            $imageUrl = $this->toPublicUrl($imageUrl);
        }

        // Calculate standard fallback variables once at the top of toArray (Exec #17)
        $ticket = $this->ticket_range ?? $this->ticket_price ?? 'Free';
        $road = $this->road_type ?? $this->road_condition ?? '';
        $vehicle = $this->vehicle_access ?? '';
        $parkingRange = $this->parking_range ?? '';
        $parkingAvail = $this->parking_avail ?? ($parkingRange === 'Available' ? 'yes' : 'no');
        $bestTime = $this->best_time ?? $this->best_time_to_visit ?? '';
        $riskTags = $this->risk_tags ?? [];
        $facilities = $this->facilities ?? [];
        $arSupported = (bool) $this->ar_supported;
        $arTier = (int) ($this->ar_tier ?? 3);
        $arBrandName = $this->ar_brand_name ?? '';
        $arModelUrl = $this->ar_model_url ?? '';
        $arHistoricalModelUrl = $this->ar_historical_model_url ?? '';
        $arModelScale = (float) ($this->ar_model_scale ?? 0.01);
        $historicalPeriod = $this->historical_period ?? '';
        $accessTier = $this->access_tier ?? 'Free';

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
            'ticket_range' => $ticket,
            'ticketRange' => $ticket,
            'road_type' => $road,
            'roadType' => $road,
            'vehicle_access' => $vehicle,
            'vehicleAccess' => $vehicle,
            'opening_hours' => $this->opening_hours ?? '',
            'mobile_signal' => $this->mobile_signal ?? '',
            'activities' => $this->activities ?? '',
            'tourist_popularity' => $this->tourist_popularity ?? '',
            'family_friendly' => $this->family_friendly ?? '',
            'budget_category' => $this->budget_category ?? '',
            'parking_avail' => $parkingAvail,
            'parking_range' => $parkingRange,
            'parkingRange' => $parkingRange,
            'toilets' => $this->toilets ?? '',
            'food_nearby' => $this->food_nearby ?? '',
            'wheelchair_access' => $this->wheelchair_access ?? '',
            'camping_allowed' => $this->camping_allowed ?? '',
            'safety_level' => $this->safety_level ?? '',
            'wildlife_hazard' => $this->wildlife_hazard ?? '',
            'guide_required' => $this->guide_required ?? '',
            'rain_sensitivity' => $this->rain_sensitivity ?? '',
            'monsoon_note' => $this->monsoon_note ?? '',
            'best_time' => $bestTime,
            'bestTime' => $bestTime,
            'height_m' => $this->height_m ?? '0',
            'length_km' => $this->length_km ?? '0',
            'surfing' => $this->surfing ?? 'no',
            'risk_tags' => $riskTags,
            'riskTags' => $riskTags,
            'facilities' => $facilities,
            'ar_supported' => $arSupported,
            'arSupported' => $arSupported,
            'ar_tier' => $arTier,
            'arTier' => $arTier,
            'ar_brand_name' => $arBrandName,
            'arBrandName' => $arBrandName,
            'ar_model_url' => $arModelUrl,
            'arModelUrl' => $arModelUrl,
            'ar_historical_model_url' => $arHistoricalModelUrl,
            'arHistoricalModelUrl' => $arHistoricalModelUrl,
            'ar_model_scale' => $arModelScale,
            'arModelScale' => $arModelScale,
            'historical_period' => $historicalPeriod,
            'historicalPeriod' => $historicalPeriod,
            'ar_file_size_mb' => (float) ($this->ar_file_size_mb ?? 0),
            'audio_guide_url_si' => $this->audio_guide_url_si ?? '',
            'audio_guide_url_en' => $this->audio_guide_url_en ?? '',
            'geohash' => $this->geohash ?? '',
            'image_url' => $imageUrl,
            'imageUrl' => $imageUrl,
            'images' => $this->relationLoaded('images') ? $this->images->map(function ($img) {
                $thumb = $this->toPublicUrl($img->thumb_path);
                $full = $this->toPublicUrl($img->full_path);
                return [
                    'id' => $img->id,
                    'thumb_path' => $thumb,
                    'thumbPath' => $thumb,
                    'full_path' => $full,
                    'fullPath' => $full,
                    'is_cover' => (bool) $img->is_cover,
                    'isCover' => (bool) $img->is_cover,
                ];
            }) : [],
            'access_tier' => $accessTier,
            'accessTier' => $accessTier,
            'isPremium' => in_array($accessTier, ['PRO', 'VIP']),
            'sync_version' => (int) $this->sync_version,
        ];
    }
}
