<?php

namespace App\Observers;

use App\Models\Event;
use Illuminate\Support\Facades\DB;

class EventObserver
{
    /**
     * Mirrors PlaceObserver::saving() — only bumps the shared global
     * sync_version counter once the event is (or is becoming) approved, since
     * the mobile app's /discovery/events endpoint only ever returns approved
     * events. Shares the same sync_counter row places use; delta-sync clients
     * don't care whose ID space a version number came from.
     */
    public function saving(Event $event)
    {
        if ($event->status !== Event::STATUS_APPROVED) {
            return;
        }

        if (!$event->isDirty('sync_version')) {
            DB::transaction(function () use ($event) {
                $counter = DB::table('sync_counter')->where('id', 1)->lockForUpdate()->first();
                $newVersion = ($counter ? $counter->current_version : 0) + 1;
                DB::table('sync_counter')->where('id', 1)->update(['current_version' => $newVersion]);
                $event->sync_version = $newVersion;
            });
        }
    }

    public function deleting(Event $event)
    {
        DB::transaction(function () use ($event) {
            $counter = DB::table('sync_counter')->where('id', 1)->lockForUpdate()->first();
            $newVersion = ($counter ? $counter->current_version : 0) + 1;
            DB::table('sync_counter')->where('id', 1)->update(['current_version' => $newVersion]);

            $event->setAttribute('is_deleted', true);
            $event->setAttribute('sync_version', $newVersion);
            $event->saveQuietly();

            $event->images()->delete();
        });

        return false;
    }
}
