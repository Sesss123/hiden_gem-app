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
        // Capped and hardcoded to 100 max per request to avoid memory exhaustion (BUG-046)
        $limit = 100;

        $query = Place::with('images')->where('sync_version', '>', $sinceVersion);
        if ($sinceVersion == 0) {
            $query->where('is_deleted', false);
        }
        $places = $query->orderBy('sync_version', 'asc')->limit($limit)->get();

        $upsertPlaces = [];
        $deletedIds = [];
        $maxVersion = $sinceVersion;

        foreach ($places as $place) {
            if ($place->sync_version > $maxVersion) {
                $maxVersion = $place->sync_version;
            }

            if ($place->is_deleted) {
                if ($sinceVersion > 0) {
                    $deletedIds[] = $place->id;
                }
            } else {
                $upsertPlaces[] = (new \App\Http\Resources\PlaceResource($place))->resolve();
            }
        }

        $hasMore = $places->count() >= $limit;

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
        $cursor = $request->query('cursor');
        $limit = 100;

        $query = Place::with('images')
            ->where('is_deleted', false);

        if ($cursor) {
            $query->where('id', '>', $cursor);
        }

        $places = $query->orderBy('id', 'asc')
            ->limit($limit)
            ->get();

        $formatted = [];
        foreach ($places as $place) {
            $formatted[] = (new \App\Http\Resources\PlaceResource($place))->resolve();
        }

        $nextCursor = $places->last()?->id;
        $hasMore = $places->count() >= $limit;

        return response()->json([
            'places' => $formatted,
            'next_cursor' => $nextCursor,
            'has_more' => $hasMore,
        ]);
    }
}
