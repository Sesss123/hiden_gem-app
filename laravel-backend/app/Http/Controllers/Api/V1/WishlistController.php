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

        $existing = Wishlist::where('user_id', $user->id)
                            ->where('place_id', $place->id)
                            ->first();

        if ($existing) {
            // Remove from wishlist
            $existing->delete();
            return response()->json([
                'status' => 'success',
                'bookmarked' => false,
                'message' => 'Removed from your Saved Hidden Gems.',
            ]);
        } else {
            // Add to wishlist
            Wishlist::create([
                'user_id' => $user->id,
                'place_id' => $place->id,
            ]);
            return response()->json([
                'status' => 'success',
                'bookmarked' => true,
                'message' => 'Saved to your Hidden Gems Wishlist!',
            ], 201);
        }
    }
}
