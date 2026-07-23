<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\FirestoreService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

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
     * GET /v1/bookings/priority-check?guideId=...
     *
     * Returns whether the given guide's active subscription grants the
     * 'priorityLeads' capability. Runs server-side because firestore.rules
     * only allows a subscriptions/{subId} doc to be read by its own
     * accountId — a tourist submitting a booking can never read the guide's
     * subscription directly to compute this client-side. Mirrors
     * SubscriptionService._planCapabilities (Flutter).
     */
    public function priorityCheck(Request $request, FirestoreService $firestore)
    {
        $guideId = $request->query('guideId');
        if (!$guideId) {
            return response()->json(['error' => 'guideId is required'], 422);
        }

        $planCapabilities = [
            'pro' => ['priorityLeads'],
            'elite' => ['priorityLeads'],
        ];

        try {
            $sub = $firestore->findSubscriptionByAccountId($guideId);
            $planId = ($sub && ($sub['status'] ?? null) === 'active') ? ($sub['planId'] ?? 'free') : 'free';
            $isPriority = in_array('priorityLeads', $planCapabilities[$planId] ?? [], true);

            return response()->json(['isPriority' => $isPriority]);
        } catch (\Exception $e) {
            Log::error('Booking priority-check failed', ['guide_id' => $guideId, 'error' => $e->getMessage()]);
            // Fail closed — a booking should never be blocked by this check,
            // and understating priority is safe (worst case: a priority lead
            // isn't highlighted), unlike overstating it.
            return response()->json(['isPriority' => false]);
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

        // Security: verify bookingId is a real booking the caller actually
        // made for this guide, so an arbitrary authenticated user can't spam
        // POST here with any guideId to inflate a competitor's counter.
        $booking = $firestore->getDocument('booking_requests', $bookingId);
        if (!$booking || ($booking['touristId'] ?? null) !== (string) $request->user()->firebase_uid || ($booking['guideId'] ?? null) !== $guideId) {
            return response()->json(['error' => 'Booking not found or does not belong to you.'], 403);
        }

        try {
            $listings = $firestore->queryDocuments('guide_listings', 'guideId', 'EQUAL', $guideId, 1);
            if (empty($listings)) {
                // Guide has no listing yet — nothing to increment. The booking itself
                // already succeeded (this endpoint only updates an analytics counter),
                // so don't fail the tourist's flow over it — but this previously went
                // completely unlogged, making it invisible that a booking landed on a
                // guide who can never see bookingRequestsCount update. The real fix is
                // BookingRequestScreen checking listing existence before allowing the
                // booking at all (see MarketplaceRepository.getListing usage there).
                Log::warning('Booking notify-guide: no listing found for guide, counter not incremented', [
                    'guide_id' => $guideId,
                    'booking_id' => $bookingId,
                ]);
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

    /**
     * POST /v1/bookings/{bookingId}/quote
     *
     * Guide sets a price on a pending booking, folding "accept + quote" into
     * one action. quotedPrice/currency/status are all in firestore.rules'
     * locked-field list (see booking_requests match block) — a guide's client
     * can never set them via a direct Firestore write, so this goes through
     * the Admin SDK (FirestoreService) exactly like PayHereController::notify()
     * later reads quotedPrice server-side to build the actual payment amount.
     */
    public function sendQuote(Request $request, string $bookingId, FirestoreService $firestore)
    {
        $validator = Validator::make($request->all(), [
            'amount' => 'required|numeric|min:0.01',
            'currency' => 'nullable|string|max:10',
        ]);
        if ($validator->fails()) {
            return response()->json(['error' => 'Validation failed.', 'errors' => $validator->errors()], 422);
        }

        $booking = $firestore->getDocument('booking_requests', $bookingId);
        if (!$booking) {
            return response()->json(['error' => 'Booking not found.'], 404);
        }

        // Only the booking's own guide may quote it.
        if (($booking['guideId'] ?? null) !== (string) $request->user()->firebase_uid) {
            return response()->json(['error' => 'This booking does not belong to you.'], 403);
        }

        if (($booking['status'] ?? null) !== 'pending') {
            return response()->json(['error' => 'This booking has already been responded to.'], 422);
        }

        try {
            $firestore->updateBooking($bookingId, [
                'quotedPrice' => (float) $request->input('amount'),
                'currency' => $request->input('currency', 'LKR'),
                'status' => 'accepted',
            ]);
        } catch (\Exception $e) {
            Log::error('Booking sendQuote: Firestore update failed', [
                'guide_id' => $booking['guideId'],
                'booking_id' => $bookingId,
                'error' => $e->getMessage(),
            ]);
            return response()->json(['error' => 'Failed to save the quote.'], 500);
        }

        return response()->json(['status' => 'ok']);
    }
}
