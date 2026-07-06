<?php

namespace App\Observers;

use App\Models\PlaceImage;
use Illuminate\Support\Facades\DB;

class PlaceImageObserver
{
    /**
     * Handle the PlaceImage "saving" event.
     */
    public function saving(PlaceImage $image)
    {
        // BUG-115 / BUG-135: Deduplicate save updates using unique constraint checks to prevent parallel duplicates
        $duplicate = DB::table('place_images')
            ->where('place_id', $image->place_id)
            ->where('full_path', $image->full_path)
            ->where('id', '!=', $image->id)
            ->exists();
        if ($duplicate) {
            throw new \Exception("Duplicate image entry detected for this place.");
        }

        if (!$image->isDirty('sync_version')) {
            // Inherit the parent place's sync_version to prevent delta sync gaps
            if ($image->place) {
                $image->sync_version = $image->place->sync_version;
            } else {
                $image->sync_version = 0;
            }
        }
    }

    // BUG-075: Wrap parent touch in a transaction block with safety locks to prevent concurrent corruption
    protected function touchParentPlace($place)
    {
        if ($place) {
            // Retrieve or initialize request-bound registry of touched places (resets on Swoole request terminate)
            $registry = app()->has('touched_places_registry') ? app('touched_places_registry') : [];
            
            if (!in_array($place->id, $registry)) {
                $registry[] = $place->id;
                app()->instance('touched_places_registry', $registry);
                
                DB::transaction(function () use ($place) {
                    $lockedPlace = DB::table('places')->where('id', $place->id)->lockForUpdate()->first();
                    if ($lockedPlace) {
                        $place->touch();
                    }
                }, 5);
            }
        }
    }

    /**
     * Handle the PlaceImage "saved" event.
     * Rule: Image change = Place change. Touching parent Place triggers PlaceObserver to bump place version.
     */
    public function saved(PlaceImage $image)
    {
        // BUG-095: Touch parent only if newly created or if existing attributes actually changed
        if ($image->wasRecentlyCreated || $image->wasChanged(['thumb_path', 'full_path', 'is_cover', 'sort_order'])) {
            $this->touchParentPlace($image->place);
        }
    }

    /**
     * Handle the PlaceImage "deleted" event.
     * Rule: Image change = Place change. Touching parent Place triggers PlaceObserver to bump place version.
     */
    public function deleted(PlaceImage $image)
    {
        // BUG-075: Deletion tracking wrapped in transaction via touchParentPlace
        $this->touchParentPlace($image->place);
    }
}
