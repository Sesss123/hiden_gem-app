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
        if (!$image->isDirty('sync_version')) {
            DB::transaction(function () use ($image) {
                $counter = DB::table('sync_counter')->where('id', 1)->lockForUpdate()->first();
                $newVersion = ($counter ? $counter->current_version : 0) + 1;
                DB::table('sync_counter')->where('id', 1)->update(['current_version' => $newVersion]);
                $image->sync_version = $newVersion;
            });
        }
    }

    /**
     * Handle the PlaceImage "saved" event.
     * Rule: Image change = Place change. Touching parent Place triggers PlaceObserver to bump place version.
     */
    public function saved(PlaceImage $image)
    {
        if ($image->place) {
            $image->place->touch();
        }
    }

    /**
     * Handle the PlaceImage "deleted" event.
     */
    public function deleted(PlaceImage $image)
    {
        if ($image->place) {
            $image->place->touch();
        }
    }
}
