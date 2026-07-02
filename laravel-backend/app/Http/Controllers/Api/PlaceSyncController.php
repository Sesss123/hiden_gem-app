<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Place;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class PlaceSyncController extends Controller
{
    /**
     * GET /api/v1/places/check-version
     * Lightweight ping returning the global monotonic sequence counter.
     */
    public function checkVersion(Request $request)
    {
        $version = DB::table('sync_counter')->where('id', 1)->value('current_version');
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
        $limit = min((int) $request->query('limit', 100), 500);

        $places = Place::with('images')
            ->where('sync_version', '>', $sinceVersion)
            ->orderBy('sync_version', 'asc')
            ->limit($limit)
            ->get();

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
}
