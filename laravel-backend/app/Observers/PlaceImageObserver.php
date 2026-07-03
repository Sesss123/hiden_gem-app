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
            DB::transaction(function () use ($image) {
                $counter = DB::table('sync_counter')->where('id', 1)->lockForUpdate()->first();
                $newVersion = ($counter ? $counter->current_version : 0) + 1;
                DB::table('sync_counter')->where('id', 1)->update(['current_version' => $newVersion]);
                $image->sync_version = $newVersion;
            });
        }
    }

    protected static $touchedPlaces = [];

    // BUG-075: Wrap parent touch in a transaction block with safety locks to prevent concurrent corruption
    protected function touchParentPlace($place)
    {
        if ($place && !in_array($place->id, self::$touchedPlaces)) {
            self::$touchedPlaces[] = $place->id;
            DB::transaction(function () use ($place) {
                $lockedPlace = DB::table('places')->where('id', $place->id)->lockForUpdate()->first();
                if ($lockedPlace) {
                    $place->touch();
                }
            }, 5);
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
