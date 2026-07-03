<?php

namespace App\Observers;

use App\Models\Place;
use Illuminate\Support\Facades\DB;

class PlaceObserver
{
    /**
     * Handle the Place "saving" event.
     * Automatically locks sequence row and increments global sync_version on any update/insert.
     * BUG-062: Uses a named savepoint via DB::transaction to correctly handle nested saves.
     */
    public function saving(Place $place)
    {
        if (!$place->isDirty('sync_version')) {
            // Use a nested savepoint so this works even inside an outer transaction
            DB::transaction(function () use ($place) {
                $counter = DB::table('sync_counter')->where('id', 1)->lockForUpdate()->first();
                $newVersion = ($counter ? $counter->current_version : 0) + 1;
                DB::table('sync_counter')->where('id', 1)->update(['current_version' => $newVersion]);
                $place->sync_version = $newVersion;
            }, 5); // Retry up to 5 times on lock exceptions
        }
    }

    public function deleting(Place $place)
    {
        DB::transaction(function () use ($place) {
            $counter = DB::table('sync_counter')->where('id', 1)->lockForUpdate()->first();
            $newVersion = ($counter ? $counter->current_version : 0) + 1;
            DB::table('sync_counter')->where('id', 1)->update(['current_version' => $newVersion]);

            // Set model attributes so the model in memory matches the database state
            $place->setAttribute('is_deleted', true);
            $place->setAttribute('sync_version', $newVersion);
            $place->save();

            // BUG-082 / BUG-122: Deletion fails to clean up references in dependent tables
            DB::table('wishlists')->where('place_id', $place->id)->delete();
            DB::table('place_images')->where('place_id', $place->id)->delete();
        }, 5); // Retry up to 5 times on lock exceptions

        // Return false to cancel physical SQL DELETE execution
        return false;
    }
}
