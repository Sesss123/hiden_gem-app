<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Services\FirestoreService;
use App\Traits\LogsAdminActivity;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class BookingController extends Controller
{
    use LogsAdminActivity;

    private FirestoreService $firestoreService;

    public function __construct()
    {
        $this->firestoreService = new FirestoreService();
    }

    /**
     * List booking_requests from Firestore, filtered by status. Statuses
     * mirror BookingRequest.status on the Flutter side: pending, accepted,
     * declined, expired, cancelled_by_tourist, cancelled_by_guide,
     * session_ready, completed.
     */
    public function index(Request $request)
    {
        $status = $request->input('status', 'pending');

        $bookings = $status === 'all'
            ? $this->firestoreService->listDocuments('booking_requests')
            : $this->firestoreService->queryDocuments('booking_requests', 'status', 'EQUAL', $status);

        usort($bookings, fn ($a, $b) => strcmp($b['createdAt'] ?? '', $a['createdAt'] ?? ''));

        return view('admin.bookings.index', compact('bookings', 'status'));
    }

    public function show(string $id)
    {
        $booking = $this->firestoreService->getDocument('booking_requests', $id);
        abort_if($booking === null, 404);

        $session = null;
        if (!empty($booking['linkedSessionId'])) {
            $session = $this->firestoreService->getDocument('tour_sessions', $booking['linkedSessionId']);
        }

        return view('admin.bookings.show', compact('booking', 'session'));
    }

    /**
     * Admin-initiated cancellation — used for disputes/no-shows/fraud where
     * neither party cancels through the normal app flow. Mirrors the status
     * value the app itself already understands (cancelled_by_guide is reused
     * here since the app has no dedicated "cancelled_by_admin" status yet;
     * the admin's reason is recorded separately in responseNote).
     */
    public function cancel(Request $request, string $id)
    {
        $request->validate([
            'reason' => 'required|string|max:1000',
        ]);

        $booking = $this->firestoreService->getDocument('booking_requests', $id);
        abort_if($booking === null, 404);

        $ok = $this->firestoreService->patchDocument('booking_requests', $id, [
            'status' => 'cancelled_by_guide',
            'responseNote' => '[Admin cancellation] ' . $request->input('reason'),
            'respondedAt' => now()->toIso8601String(),
        ]);

        if (!$ok) {
            return back()->withErrors(['error' => 'Could not cancel the booking — the update failed. Please try again.']);
        }

        // This is exactly the kind of contested action (dispute/no-show/
        // fraud, per this method's own doc comment) an audit trail exists
        // for — previously unlogged.
        $this->logAdminAction('booking.cancelled', 'Booking', $id, ['reason' => $request->input('reason')]);

        return redirect()->route('admin.bookings.index', ['status' => $booking['status'] ?? 'pending'])
            ->with('success', 'Booking cancelled by admin.');
    }

    /**
     * Admin-initiated refund — deliberately not tourist-self-service (no
     * client-facing "request a refund" flow exists) so every refund goes
     * through a human review first, mirroring cancel()'s dispute-handling
     * shape. Calls PayHere's merchant refund API using the stored
     * paymentId from the original notify() webhook, then marks the booking
     * refunded via the same Admin-SDK path everything else in this
     * controller already uses.
     */
    public function refund(Request $request, string $id)
    {
        $request->validate([
            'reason' => 'required|string|max:1000',
        ]);

        $booking = $this->firestoreService->getDocument('booking_requests', $id);
        abort_if($booking === null, 404);

        if (($booking['payoutStatus'] ?? 'pending') !== 'paid') {
            return back()->withErrors(['error' => 'Only a paid booking can be refunded.']);
        }

        $paymentId = $booking['paymentId'] ?? null;
        if (!$paymentId) {
            return back()->withErrors(['error' => 'This booking has no recorded payment ID — cannot refund.']);
        }

        $appId = config('services.payhere.app_id');
        $appSecret = config('services.payhere.app_secret');
        if (empty($appId) || empty($appSecret)) {
            return back()->withErrors(['error' => 'PayHere merchant API credentials are not configured — refunds are not available yet.']);
        }

        try {
            $this->callPayHereRefund($paymentId, $appId, $appSecret);
        } catch (\Exception $e) {
            Log::error('Admin refund: PayHere refund call failed', [
                'booking_id' => $id,
                'payment_id' => $paymentId,
                'error' => $e->getMessage(),
            ]);
            return back()->withErrors(['error' => 'PayHere refund request failed: ' . $e->getMessage()]);
        }

        $ok = $this->firestoreService->patchDocument('booking_requests', $id, [
            'payoutStatus' => 'refunded',
            'responseNote' => '[Admin refund] ' . $request->input('reason'),
            'refundedAt' => now()->toIso8601String(),
        ]);

        if (!$ok) {
            // PayHere has already refunded the money at this point — a failed
            // Firestore write here is a bookkeeping-only problem, not a
            // failed refund. Surface it clearly rather than silently
            // retrying the PayHere call (which would double-refund).
            return back()->withErrors(['error' => 'PayHere refund succeeded, but updating the booking record failed. Refund the Firestore status manually and check logs.']);
        }

        $this->logAdminAction('booking.refunded', 'Booking', $id, ['reason' => $request->input('reason'), 'payment_id' => $paymentId]);

        return redirect()->route('admin.bookings.show', $id)
            ->with('success', 'Booking refunded.');
    }

    /**
     * PayHere merchant API refund call. Authenticates via OAuth client-
     * credentials (app_id/app_secret, distinct from the checkout
     * merchant_id/merchant_secret used by PayHereController) to get a
     * bearer token, then POSTs the refund request.
     *
     * NOTE: verify this endpoint/payload shape against PayHere's current
     * merchant API docs before relying on it in production — it is not
     * exercised anywhere else in this codebase and PayHere's API has
     * changed shape between versions historically.
     */
    private function callPayHereRefund(string $paymentId, string $appId, string $appSecret): void
    {
        $sandbox = config('services.payhere.sandbox');
        $base = $sandbox ? 'https://sandbox.payhere.lk' : 'https://www.payhere.lk';

        $tokenResponse = Http::asForm()->withBasicAuth($appId, $appSecret)
            ->post("{$base}/merchant/v1/oauth/token", ['grant_type' => 'client_credentials']);

        if (!$tokenResponse->successful()) {
            throw new \RuntimeException('Could not authenticate with PayHere merchant API: ' . $tokenResponse->body());
        }

        $accessToken = $tokenResponse->json('access_token');
        if (!$accessToken) {
            throw new \RuntimeException('PayHere merchant API did not return an access token.');
        }

        $refundResponse = Http::withToken($accessToken)
            ->post("{$base}/merchant/v1/payment/refund", ['payment_id' => $paymentId]);

        if (!$refundResponse->successful()) {
            throw new \RuntimeException('PayHere refund request was rejected: ' . $refundResponse->body());
        }
    }
}
