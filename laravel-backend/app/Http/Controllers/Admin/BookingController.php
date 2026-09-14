<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Services\FirestoreService;
use App\Traits\LogsAdminActivity;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Cache;

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

        // Collect tourist and guide UIDs to hydrate profiles in batch
        $uids = [];
        foreach ($bookings as $b) {
            if (!empty($b['touristId'])) $uids[$b['touristId']] = true;
            if (!empty($b['guideId'])) $uids[$b['guideId']] = true;
        }

        $userProfiles = $this->hydrateUserIdentities(array_keys($uids));

        foreach ($bookings as &$booking) {
            $this->enrichBookingData($booking, $userProfiles);
        }
        unset($booking);

        usort($bookings, fn ($a, $b) => strcmp($b['createdAt'] ?? '', $a['createdAt'] ?? ''));

        return view('admin.bookings.index', compact('bookings', 'status'));
    }

    public function show(string $id)
    {
        $booking = $this->firestoreService->getDocument('booking_requests', $id);
        abort_if($booking === null, 404);

        $uids = array_filter([$booking['touristId'] ?? null, $booking['guideId'] ?? null]);
        $userProfiles = $this->hydrateUserIdentities($uids);
        $this->enrichBookingData($booking, $userProfiles);

        $session = null;
        if (!empty($booking['linkedSessionId'])) {
            $session = $this->firestoreService->getDocument('tour_sessions', $booking['linkedSessionId']);
        }

        return view('admin.bookings.show', compact('booking', 'session'));
    }

    /**
     * Batch resolve user profiles from MySQL users or Firestore users cache.
     */
    private function hydrateUserIdentities(array $uids): array
    {
        if (empty($uids)) return [];

        $profiles = [];

        // 1. Check local MySQL users first
        try {
            $localUsers = \App\Models\User::whereIn('firebase_uid', $uids)->get();
            foreach ($localUsers as $lu) {
                $profiles[$lu->firebase_uid] = [
                    'name' => $lu->name,
                    'email' => $lu->email,
                    'role' => $lu->role,
                ];
            }
        } catch (\Throwable $e) {
            // Non-blocking
        }

        // 2. Lookup remaining from Firestore
        foreach ($uids as $uid) {
            if (!isset($profiles[$uid])) {
                $cacheKey = "fs_user_identity_{$uid}";
                $profiles[$uid] = Cache::remember($cacheKey, 600, function () use ($uid) {
                    $doc = $this->firestoreService->getDocument('users', $uid);
                    if ($doc) {
                        return [
                            'name' => $doc['displayName'] ?? $doc['name'] ?? null,
                            'email' => $doc['email'] ?? null,
                            'role' => $doc['role'] ?? 'tourist',
                        ];
                    }
                    return null;
                });
            }
        }

        return $profiles;
    }

    /**
     * Formats Colombo local time, masks emails, and computes human-readable pricing states.
     */
    private function enrichBookingData(array &$b, array $userProfiles): void
    {
        $tUid = $b['touristId'] ?? '';
        $gUid = $b['guideId'] ?? '';

        $tProfile = $userProfiles[$tUid] ?? null;
        $gProfile = $userProfiles[$gUid] ?? null;

        $b['touristName'] = $tProfile['name'] ?? (strlen($tUid) > 10 ? substr($tUid, 0, 6) . '...' . substr($tUid, -4) : ($tUid ?: 'Unknown'));
        $b['touristEmailMasked'] = !empty($tProfile['email']) ? $this->maskEmail($tProfile['email']) : null;
        $b['touristRole'] = $tProfile['role'] ?? 'tourist';

        $b['guideName'] = $gProfile['name'] ?? (strlen($gUid) > 10 ? substr($gUid, 0, 6) . '...' . substr($gUid, -4) : ($gUid ?: 'Unknown'));
        $b['guideEmailMasked'] = !empty($gProfile['email']) ? $this->maskEmail($gProfile['email']) : null;
        $b['guideRole'] = $gProfile['role'] ?? 'guide';

        // Formats Colombo local time
        if (!empty($b['createdAt'])) {
            try {
                $b['createdAtColombo'] = \Carbon\Carbon::parse($b['createdAt'])->setTimezone('Asia/Colombo')->format('M d, Y · h:i A');
            } catch (\Throwable $e) {
                $b['createdAtColombo'] = $b['createdAt'];
            }
        } else {
            $b['createdAtColombo'] = 'N/A';
        }
        $b['requestedDateColombo'] = $this->formatColomboDate($b['requestedDate'] ?? null, true);

        // Price & Payment State resolution
        $payoutStatus = $b['payoutStatus'] ?? 'pending';
        $paymentStatus = strtolower((string) ($b['paymentStatus'] ?? ''));
        $quotedPrice = $b['quotedPrice'] ?? null;
        $st = $b['status'] ?? 'pending';
        $paymentVerified = $payoutStatus === 'paid'
            || in_array($paymentStatus, ['paid', 'completed', 'success', 'verified'], true)
            || !empty($b['paidAt']);

        if ($quotedPrice === null || $quotedPrice <= 0) {
            $b['priceStateLabel'] = 'Quote Pending';
            $b['priceStateClass'] = 'text-slate-500 bg-slate-800/40 border-slate-700';
        } elseif ($payoutStatus === 'refunded') {
            $b['priceStateLabel'] = 'Refunded';
            $b['priceStateClass'] = 'text-orange-400 bg-orange-500/10 border-orange-500/30';
        } elseif ($paymentVerified) {
            $b['priceStateLabel'] = 'Payment Verified';
            $b['priceStateClass'] = 'text-emerald-400 bg-emerald-500/10 border-emerald-500/30';
        } elseif ($st === 'completed') {
            $b['priceStateLabel'] = 'Payment Record Missing';
            $b['priceStateClass'] = 'text-red-400 bg-red-500/10 border-red-500/30';
        } else {
            $b['priceStateLabel'] = 'Quoted (Payment Pending)';
            $b['priceStateClass'] = 'text-amber-400 bg-amber-500/10 border-amber-500/30';
        }
        $b['currencyLabel'] = !empty($b['currency']) ? strtoupper((string) $b['currency']) : null;
    }

    private function formatColomboDate($value, bool $preserveDateOnly = false): string
    {
        if (empty($value)) return 'N/A';
        if ($preserveDateOnly && preg_match('/^\d{4}-\d{2}-\d{2}$/', (string) $value)) {
            return \Carbon\Carbon::parse($value, 'Asia/Colombo')->format('M d, Y');
        }
        try {
            return \Carbon\Carbon::parse($value)->setTimezone('Asia/Colombo')->format('M d, Y · h:i A');
        } catch (\Throwable $e) {
            return 'Invalid date';
        }
    }

    private function maskEmail(string $email): string
    {
        $parts = explode('@', $email);
        if (count($parts) !== 2) return $email;
        $name = $parts[0];
        $domain = $parts[1];
        $maskedName = strlen($name) > 2 ? substr($name, 0, 2) . '***' : $name . '***';
        return $maskedName . '@' . $domain;
    }

    /**
     * Admin-initiated cancellation — used for disputes/no-shows/fraud where
     * neither party cancels through the normal app flow. Mirrors the status
     * Uses a distinct status so guide performance metrics and dispute history
     * never misattribute an administrator action to the guide.
     */
    public function cancel(Request $request, string $id)
    {
        $request->validate([
            'reason' => 'required|string|max:1000',
        ]);

        $booking = $this->firestoreService->getDocument('booking_requests', $id);
        abort_if($booking === null, 404);

        $ok = $this->firestoreService->patchDocument('booking_requests', $id, [
            'status' => 'cancelled_by_admin',
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

        $lock = Cache::lock("admin-refund:{$id}", 120);
        if (!$lock->get()) {
            return back()->withErrors(['error' => 'A refund for this booking is already being processed.']);
        }

        try {
        $booking = $this->firestoreService->getDocument('booking_requests', $id);
        abort_if($booking === null, 404);

        if (in_array($booking['refundStatus'] ?? null, ['processing', 'completed', 'manual_reconciliation_required'], true)
            || ($booking['payoutStatus'] ?? null) === 'refunded') {
            return back()->withErrors(['error' => 'This refund was already started or completed. Check PayHere before any manual retry.']);
        }

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

        if (!$this->firestoreService->patchDocument('booking_requests', $id, [
            'refundStatus' => 'processing',
            'refundStartedAt' => now()->toIso8601String(),
            'refundReason' => $request->input('reason'),
        ])) {
            return back()->withErrors(['error' => 'Could not reserve this refund safely. No payment action was made.']);
        }

        try {
            $this->callPayHereRefund($paymentId, $appId, $appSecret);
        } catch (\Exception $e) {
            $this->firestoreService->patchDocument('booking_requests', $id, ['refundStatus' => 'failed']);
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
            'refundStatus' => 'completed',
        ]);

        if (!$ok) {
            // PayHere has already refunded the money at this point — a failed
            // Firestore write here is a bookkeeping-only problem, not a
            // failed refund. Surface it clearly rather than silently
            // retrying the PayHere call (which would double-refund).
            $this->firestoreService->patchDocument('booking_requests', $id, ['refundStatus' => 'manual_reconciliation_required']);
            return back()->withErrors(['error' => 'PayHere refund succeeded, but updating the booking record failed. Do not retry the gateway refund; reconcile Firestore manually.']);
        }

        $this->logAdminAction('booking.refunded', 'Booking', $id, ['reason' => $request->input('reason'), 'payment_id' => $paymentId]);

        return redirect()->route('admin.bookings.show', $id)
            ->with('success', 'Booking refunded.');
        } finally {
            optional($lock)->release();
        }
    }

    
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
