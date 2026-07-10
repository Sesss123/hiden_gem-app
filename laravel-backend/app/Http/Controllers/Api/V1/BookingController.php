<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\FirestoreService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class BookingController extends Controller
{
    /**
     * GET /v1/bookings/quota-check?guideId=...
     *
     * Returns whether the given guide has hit their monthly booking quota.
     * Runs server-side because firestore.rules can't let a tourist client
     * query another guide's full booking_requests list directly — the rule
     * can only be proven safe for the guide themselves, not an arbitrary
     * tourist checking a guide's booking count before their own doc exists.
     * Mirrors the plan limits in SubscriptionService._getPlanLimit (Flutter).
     */
    public function quotaCheck(Request $request, FirestoreService $firestore)
    {
        $guideId = $request->query('guideId');
        if (!$guideId) {
            return response()->json(['error' => 'guideId is required'], 422);
        }

        $planLimits = [
            'free' => 5, 'pro' => 50, 'elite' => 500,
            'starter' => 30, 'growth' => 200, 'enterprise' => 9999,
        ];

        try {
            $sub = $firestore->findSubscriptionByAccountId($guideId);
            $planId = ($sub && ($sub['status'] ?? null) === 'active') ? ($sub['planId'] ?? 'free') : 'free';
            $maxQuota = $planLimits[$planId] ?? 5;

            $startOfMonth = now()->startOfMonth()->toIso8601String();
            $currentCount = $firestore->countBookingsForGuideSince($guideId, $startOfMonth);

            return response()->json([
                'currentCount' => $currentCount,
                'maxQuota' => $maxQuota,
                'quotaExceeded' => $currentCount >= $maxQuota,
            ]);
        } catch (\Exception $e) {
            Log::error('Booking quota-check failed', ['guide_id' => $guideId, 'error' => $e->getMessage()]);
            return response()->json(['error' => 'Failed to check booking quota'], 500);
        }
    }

    /**
     * POST /v1/bookings/{bookingId}/notify-guide
     *
     * Increments the guide's guide_listings.bookingRequestsCount after a
     * tourist submits a booking. firestore.rules only allows the listing's
     * owner (the guide) to write that field, so the tourist's client can't
     * do this directly — the request just gets silently denied.
     */
    public function notifyGuide(Request $request, string $bookingId, FirestoreService $firestore)
    {
        $guideId = $request->input('guideId');
        if (!$guideId) {
            return response()->json(['error' => 'guideId is required'], 422);
        }

        try {
            $listings = $firestore->queryDocuments('guide_listings', 'guideId', 'EQUAL', $guideId, 1);
            if (empty($listings)) {
                // Guide has no listing yet — nothing to increment, not an error.
                return response()->json(['status' => 'ok', 'note' => 'no listing found for guide']);
            }

            $listingId = $listings[0]['id'];
            $currentCount = (int) ($listings[0]['bookingRequestsCount'] ?? 0);

            $firestore->patchDocument('guide_listings', $listingId, [
                'bookingRequestsCount' => $currentCount + 1,
            ]);
        } catch (\Exception $e) {
            Log::error('Booking notify-guide: Firestore update failed', [
                'guide_id' => $guideId,
                'booking_id' => $bookingId,
                'error' => $e->getMessage(),
            ]);
            return response()->json(['error' => 'Failed to update guide listing'], 500);
        }

        return response()->json(['status' => 'ok']);
    }
}
