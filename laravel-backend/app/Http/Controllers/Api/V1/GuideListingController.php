<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\FirestoreService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

/**
 * Admin moderation queue for guide_listings (marketplace listings).
 *
 * guide_listings has no MySQL-backed model — it's Firestore-only, unlike
 * guide_applications — so every method here reads/writes Firestore directly
 * via FirestoreService rather than through an Eloquent model + async sync.
 *
 * firestore.rules requires moderationStatus=='pending' and isFeatured==false
 * on client create, and blocks both fields from ever being changed by a
 * client update — this controller (Admin SDK via FirestoreService, which
 * bypasses rules entirely) is the only path that can move a listing to
 * 'approved'/'rejected' or grant isFeatured.
 */
class GuideListingController extends Controller
{
    /**
     * Admin: list guide_listings filtered by moderation status (defaults to
     * the moderation queue itself — pending listings awaiting review).
     */
    public function index(Request $request)
    {
        $firestoreService = new FirestoreService();
        $status = $request->query('moderationStatus', 'pending');

        $listings = $firestoreService->queryDocuments('guide_listings', 'moderationStatus', 'EQUAL', $status, 100);

        return response()->json([
            'status' => 'success',
            'data' => $listings,
        ], 200);
    }

    /**
     * Admin: approve a pending listing. Optionally grants isFeatured in the
     * same call if the guide holds the featuredListings entitlement — the
     * caller (admin) is expected to have already verified that via
     * SubscriptionService/hasEntitlement before setting featured=true here;
     * this endpoint does not re-check RevenueCat itself.
     */
    public function approve(Request $request, string $listingId)
    {
        $validator = Validator::make($request->all(), [
            'featured' => 'sometimes|boolean',
            'featured_days' => 'sometimes|integer|min:1|max:90',
        ]);
        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'errors' => $validator->errors(),
            ], 422);
        }

        $firestoreService = new FirestoreService();
        $listing = $firestoreService->getDocument('guide_listings', $listingId);
        if (!$listing) {
            return response()->json([
                'status' => 'error',
                'message' => 'Listing not found.',
            ], 404);
        }

        $featured = (bool) $request->input('featured', false);
        $featuredDays = (int) $request->input('featured_days', 30);

        $update = [
            'moderationStatus' => 'approved',
            'moderationNotes' => null,
            'isFeatured' => $featured,
            'featuredUntil' => $featured ? now()->addDays($featuredDays)->toIso8601String() : null,
        ];

        $ok = $firestoreService->updateGuideListing($listingId, $update);
        if (!$ok) {
            Log::error("Failed to approve guide_listings/{$listingId} in Firestore.");
            return response()->json([
                'status' => 'error',
                'message' => 'Failed to update listing in Firestore.',
            ], 500);
        }

        return response()->json([
            'status' => 'success',
            'message' => 'Listing approved.',
            'data' => array_merge($listing, $update),
        ], 200);
    }

    /**
     * Admin: reject a pending listing with a reason. Rejection also forces
     * isFeatured off — a rejected listing should never carry over a prior
     * featured grant.
     */
    public function reject(Request $request, string $listingId)
    {
        $validator = Validator::make($request->all(), [
            'moderation_notes' => 'required|string|max:1000',
        ]);
        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => 'A reason (moderation_notes) is required.',
                'errors' => $validator->errors(),
            ], 422);
        }

        $firestoreService = new FirestoreService();
        $listing = $firestoreService->getDocument('guide_listings', $listingId);
        if (!$listing) {
            return response()->json([
                'status' => 'error',
                'message' => 'Listing not found.',
            ], 404);
        }

        $update = [
            'moderationStatus' => 'rejected',
            'moderationNotes' => $request->input('moderation_notes'),
            'isFeatured' => false,
            'featuredUntil' => null,
        ];

        $ok = $firestoreService->updateGuideListing($listingId, $update);
        if (!$ok) {
            Log::error("Failed to reject guide_listings/{$listingId} in Firestore.");
            return response()->json([
                'status' => 'error',
                'message' => 'Failed to update listing in Firestore.',
            ], 500);
        }

        return response()->json([
            'status' => 'success',
            'message' => 'Listing rejected.',
            'data' => array_merge($listing, $update),
        ], 200);
    }

    /**
     * Admin: change the isFeatured grant on an already-approved listing
     * without re-running moderation (e.g. a guide's paid plan lapses and an
     * admin/scheduled job needs to turn featured off, or a support agent
     * grants it after a manual entitlement check).
     */
    public function setFeatured(Request $request, string $listingId)
    {
        $validator = Validator::make($request->all(), [
            'featured' => 'required|boolean',
            'featured_days' => 'sometimes|integer|min:1|max:90',
        ]);
        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'errors' => $validator->errors(),
            ], 422);
        }

        $firestoreService = new FirestoreService();
        $listing = $firestoreService->getDocument('guide_listings', $listingId);
        if (!$listing) {
            return response()->json([
                'status' => 'error',
                'message' => 'Listing not found.',
            ], 404);
        }
        if (($listing['moderationStatus'] ?? null) !== 'approved') {
            return response()->json([
                'status' => 'error',
                'message' => 'Only approved listings can be featured.',
            ], 422);
        }

        $featured = (bool) $request->input('featured');
        $featuredDays = (int) $request->input('featured_days', 30);

        $update = [
            'isFeatured' => $featured,
            'featuredUntil' => $featured ? now()->addDays($featuredDays)->toIso8601String() : null,
        ];

        $ok = $firestoreService->updateGuideListing($listingId, $update);
        if (!$ok) {
            Log::error("Failed to set isFeatured on guide_listings/{$listingId} in Firestore.");
            return response()->json([
                'status' => 'error',
                'message' => 'Failed to update listing in Firestore.',
            ], 500);
        }

        return response()->json([
            'status' => 'success',
            'message' => $featured ? 'Listing featured.' : 'Listing un-featured.',
            'data' => array_merge($listing, $update),
        ], 200);
    }
}
