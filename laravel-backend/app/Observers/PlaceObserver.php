<?php

namespace App\Observers;

use App\Models\Place;
use Illuminate\Support\Facades\DB;

class PlaceObserver
{
    /**
     * Handle the Place "saving" event.
     * Automatically locks sequence row and increments global sync_version on any update/insert.
     */
    public function saving(Place $place)
    {
        if (!$place->isDirty('sync_version')) {
            DB::transaction(function () use ($place) {
                $counter = DB::table('sync_counter')->where('id', 1)->lockForUpdate()->first();
                $newVersion = ($counter ? $counter->current_version : 0) + 1;
                DB::table('sync_counter')->where('id', 1)->update(['current_version' => $newVersion]);
                $place->sync_version = $newVersion;
            });
        }
    }

    /**
     * Handle the Place "deleting" event.
     * Prevents physical SQL DELETE. Converts to soft-delete with atomic version increment.
     */
    public function deleting(Place $place)
    {
        DB::transaction(function () use ($place) {
            $counter = DB::table('sync_counter')->where('id', 1)->lockForUpdate()->first();
            $newVersion = ($counter ? $counter->current_version : 0) + 1;
            DB::table('sync_counter')->where('id', 1)->update(['current_version' => $newVersion]);

            DB::table('places')->where('id', $place->id)->update([
                'is_deleted' => true,
                'sync_version' => $newVersion,
                'updated_at' => now(),
            ]);
        });

        // Return false to cancel physical SQL DELETE execution
        return false;
    }
}
