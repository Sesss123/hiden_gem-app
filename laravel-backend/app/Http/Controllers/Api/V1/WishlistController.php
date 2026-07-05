<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Place;
use App\Models\Wishlist;
use Illuminate\Http\Request;

class WishlistController extends Controller
{
    /**
     * Get all bookmarked places for the authenticated user.
     */
    public function index(Request $request)
    {
        $user = $request->user();
        $places = $user->savedPlaces()->with('images')->get();

        return response()->json([
            'status' => 'success',
            'count' => $places->count(),
            'data' => \App\Http\Resources\PlaceResource::collection($places),
        ]);
    }

    /**
     * Toggle bookmark/wishlist status for a specific place.
     */
    public function toggle(Request $request, $placeId)
    {
        $user = $request->user();
        $place = Place::find($placeId);

        if (! $place) {
            return response()->json([
                'status' => 'error',
                'message' => 'Hidden Gem not found.',
            ], 404);
        }

        $changes = $user->savedPlaces()->toggle($place->id);
        $attached = count($changes['attached']) > 0;

        return response()->json([
            'status' => 'success',
            'bookmarked' => $attached,
            'message' => $attached ? 'Saved to your Hidden Gems Wishlist!' : 'Removed from your Saved Hidden Gems.',
        ], $attached ? 201 : 200);
    }
}
