<?php

namespace App\Observers;

use App\Models\EventImage;
use Illuminate\Support\Facades\DB;

class EventImageObserver
{
    /**
     * Mirrors PlaceImageObserver — inherits the parent event's sync_version
     * on save and touches the parent on save/delete so EventObserver bumps
     * the event's own sync_version whenever its gallery changes.
     */
    public function saving(EventImage $image)
    {
        $duplicate = DB::table('event_images')
            ->where('event_id', $image->event_id)
            ->where('full_path', $image->full_path)
            ->where('id', '!=', $image->id)
            ->exists();
        if ($duplicate) {
            throw new \Exception("Duplicate image entry detected for this event.");
        }

        if (!$image->isDirty('sync_version')) {
            $image->sync_version = $image->event ? $image->event->sync_version : 0;
        }
    }

    protected function touchParentEvent($event)
    {
        if ($event) {
            DB::transaction(function () use ($event) {
                $locked = DB::table('events')->where('id', $event->id)->lockForUpdate()->first();
                if ($locked) {
                    $event->touch();
                }
            }, 5);
        }
    }

    public function saved(EventImage $image)
    {
        if ($image->wasRecentlyCreated || $image->wasChanged(['thumb_path', 'full_path', 'is_cover', 'sort_order'])) {
            $this->touchParentEvent($image->event);
        }
    }

    public function deleted(EventImage $image)
    {
        $this->touchParentEvent($image->event);
    }
}
