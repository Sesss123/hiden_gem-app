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
        $events = Event::with('images')
            ->where('is_deleted', false)
            ->where('status', Event::STATUS_APPROVED)
            ->where('is_active', true)
            ->orderBy('sync_version', 'asc')
            ->orderBy('id', 'asc')
            ->get();

        return response()->json(EventResource::collection($events)->resolve());
    }
}
