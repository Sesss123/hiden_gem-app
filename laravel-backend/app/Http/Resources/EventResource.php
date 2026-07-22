<?php

namespace App\Http\Resources;

use App\Http\Resources\Concerns\BuildsPublicStorageUrl;
use Illuminate\Http\Resources\Json\JsonResource;

class EventResource extends JsonResource
{
    use BuildsPublicStorageUrl;

    /**
     * Transform the resource into an array for API consumers (Flutter App).
     * Includes both snake_case and camelCase keys, mirroring PlaceResource.
     */
    public function toArray($request)
    {
        $imageUrl = '';
        if ($this->relationLoaded('images') && $this->images->isNotEmpty()) {
            $cover = $this->images->firstWhere('is_cover', true) ?? $this->images->first();
            if ($cover) {
                $path = $cover->thumb_path ?: $cover->full_path;
                $imageUrl = $this->toPublicUrl($path);
            }
        }

        return [
            'id' => $this->id,
            'name' => $this->name,
            'description' => $this->description ?? '',
            'category' => $this->category,
            'type' => $this->category,
            'location' => $this->location ?? '',
            'date' => $this->date,
            'start' => $this->start,
            'end' => $this->end,
            'is_active' => (bool) $this->is_active,
            'imageUrl' => $imageUrl,
            'image_url' => $imageUrl,
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
            'sync_version' => (int) $this->sync_version,
        ];
    }
}
