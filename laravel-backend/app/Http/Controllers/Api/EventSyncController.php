<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\EventResource;
use App\Models\Event;
use Illuminate\Http\Request;

class EventSyncController extends Controller
{
    /**
     * GET /discovery/events
     * DynamicContentService.fetchEvents() (Flutter) already calls this exact
     * path and does `json.decode(response.body)` straight into a List — it
     * expects a bare JSON array, not an object wrapping one, and has no
     * incremental-delta handling. Match that contract exactly rather than
     * wrapping the response (which would silently break List<dynamic> casting
     * and send every request straight to the static-dataset fallback).
     */
    public function events(Request $request)
    {
        // Cap the payload like PlaceSyncController does — this endpoint has
        // no cursor, so a hard limit is the difference between "harmless
        // today" and "unbounded once events stop being pruned."
        $events = Event::with(['images' => function ($q) {
                // Still-processing/failed uploads carry the shared
                // placeholder path, not a real photo — never ship that to
                // the app as if it were the event's actual cover image.
                $q->where('status', 'ready');
            }])
            ->where('is_deleted', false)
            ->where('status', Event::STATUS_APPROVED)
            ->where('is_active', true)
            ->orderBy('sync_version', 'asc')
            ->orderBy('id', 'asc')
            ->limit(500)
            ->get();

        return response()->json(EventResource::collection($events)->resolve());
    }
}
