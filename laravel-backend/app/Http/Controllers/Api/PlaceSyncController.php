<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Place;
use Illuminate\Http\Request;
use App\Models\SyncCounter;

class PlaceSyncController extends Controller
{
    /**
     * GET /api/v1/places/check-version
     * Lightweight ping returning the global monotonic sequence counter.
     */
    public function checkVersion(Request $request)
    {
        $version = SyncCounter::where('id', 1)->value('current_version');
        return response()->json([
            'version' => (int) ($version ?? 0)
        ]);
    }

    /**
     * GET /api/v1/places/delta?since_version=0&limit=100
     * Paginated delta sync returning changed and soft-deleted places.
     */
    public function delta(Request $request)
    {
        $sinceVersion = (int) $request->query('since_version', 0);
        // Honor client limit capped at 500 max to avoid memory exhaustion (Audit #13)
        $limit = min((int) $request->query('limit', 100), 500);

        $query = Place::withoutGlobalScope('active')->with('images');
        if ($sinceVersion > 0) {
            $query->where('sync_version', '>', $sinceVersion);
        } else {
            $query->where('is_deleted', false)->where('status', Place::STATUS_APPROVED);
        }

        // Secondary ordering by id prevents record dropping across chunk limits (Exec #10 / Audit #23)
        // Query limit + 1 to accurately determine hasMore without an extra empty round-trip (Audit #20)
        $places = $query->orderBy('sync_version', 'asc')->orderBy('id', 'asc')->limit($limit + 1)->get();

        $hasMore = $places->count() > $limit;
        if ($hasMore) {
            $places = $places->slice(0, $limit);
        }

        $deletedIds = [];
        $maxVersion = $sinceVersion;

        foreach ($places as $place) {
            if ($place->sync_version > $maxVersion) {
                $maxVersion = $place->sync_version;
            }

            // A place that's been soft-deleted, OR is no longer approved (e.g. a
            // content_manager submission that was rejected after already syncing
            // once as pending — shouldn't normally happen, but defensive), should
            // be purged from clients that already have it.
            $noLongerVisible = $place->is_deleted || $place->status !== Place::STATUS_APPROVED;
            if ($noLongerVisible) {
                if ($sinceVersion > 0) {
                    $deletedIds[] = $place->id;
                }
            }
        }

        // Use PlaceResource::collection to leverage optimized collection serialization (Exec #13)
        $activePlaces = $places->where('is_deleted', false)->where('status', Place::STATUS_APPROVED);
        $upsertPlaces = \App\Http\Resources\PlaceResource::collection($activePlaces)->resolve();

        return response()->json([
            'sync_version' => (int) $maxVersion,
            'has_more' => $hasMore,
            'next_cursor' => (int) $maxVersion,
            'upsert_places' => $upsertPlaces,
            'deleted_ids' => $deletedIds,
        ]);
    }

    /**
     * GET /api/v1/places
     * Returns all active places with cursor pagination.
     */
    public function allPlaces(Request $request)
    {
        $cursor = (int) $request->query('cursor', 0);
        $limit = min((int) $request->query('limit', 100), 500);

        $query = Place::with('images')
            ->where('is_deleted', false)
            ->where('status', Place::STATUS_APPROVED);

        if ($cursor > 0) {
            $query->where('sync_version', '>', $cursor);
        }

        // Stable monotonic ordering by sync_version and id (Exec #6 / Audit #23)
        $places = $query->orderBy('sync_version', 'asc')
            ->orderBy('id', 'asc')
            ->limit($limit + 1)
            ->get();

        $hasMore = $places->count() > $limit;
        if ($hasMore) {
            $places = $places->slice(0, $limit);
        }

        $formatted = \App\Http\Resources\PlaceResource::collection($places)->resolve();

        $nextCursor = $places->last()?->sync_version ?? 0;

        return response()->json([
            'places' => $formatted,
            'next_cursor' => $nextCursor,
            'has_more' => $hasMore,
        ]);
    }
}
