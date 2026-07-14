<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\FirestoreService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\URL;
use Illuminate\Support\Facades\Validator;

/**
 * PayHere booking-payment integration.
 *
 * WHY: bookings quote a price (booking_requests.quotedPrice) and the app
 * computes a 10% platform commission on session end, but nothing ever
 * COLLECTED the money — it moved off-platform (WhatsApp/cash) and payoutStatus
 * stayed 'pending'. This routes the tourist's payment through PayHere so the
 * platform actually captures its commission.
 *
 * FLOW:
 *   1. Tourist taps "Pay Now" on an accepted booking → app calls
 *      POST /api/v1/payments/checkout → this returns the signed PayHere
 *      checkout params (the app opens PayHere's hosted checkout with them).
 *   2. Tourist pays on PayHere.
 *   3. PayHere calls POST /api/v1/payments/notify (server-to-server) with an
 *      md5 signature we verify — this is the ONLY trusted path that marks the
 *      booking paid (payoutStatus:'paid', status:'confirmed'), via the Admin
 *      SDK (bypasses firestore.rules, which block clients from these fields).
 *
 * NOTE: real-world tour service payments MUST use a payment gateway, NOT
 * Google Play Billing (Google forbids Play Billing for physical/real-world
 * goods & services — Play Billing is only for in-app digital content, which is
 * what the premium subscriptions already use via RevenueCat).
 */
class PayHereController extends Controller
{
    private const CHECKOUT_URL_SANDBOX = 'https://sandbox.payhere.lk/pay/checkout';
    private const CHECKOUT_URL_LIVE = 'https://www.payhere.lk/pay/checkout';

    /**
     * POST /api/v1/payments/checkout   (Sanctum-auth'd tourist)
     *
     * Returns the signed parameter set the app hands to PayHere's checkout.
     * The amount is the booking's quotedPrice — the caller cannot set an
     * arbitrary amount; we read it from Firestore server-side.
     */
    public function checkout(Request $request, FirestoreService $firestore)
    {
        $validator = Validator::make($request->all(), [
            'booking_id' => 'required|string',
        ]);
        if ($validator->fails()) {
            return response()->json(['status' => 'error', 'errors' => $validator->errors()], 422);
        }

        $merchantId = config('services.payhere.merchant_id');
        $merchantSecret = config('services.payhere.merchant_secret');
        if (empty($merchantId) || empty($merchantSecret)) {
            Log::error('PayHere checkout: merchant credentials not configured.');
            return response()->json(['status' => 'error', 'message' => 'Payments are not configured.'], 503);
        }

        $bookingId = $request->input('booking_id');
        $booking = $firestore->getDocument('booking_requests', $bookingId);
        if (!$booking) {
            return response()->json(['status' => 'error', 'message' => 'Booking not found.'], 404);
        }

        // Only the tourist who owns the booking may pay for it.
        if (($booking['touristId'] ?? null) !== (string) $request->user()->firebase_uid) {
            return response()->json(['status' => 'error', 'message' => 'Not your booking.'], 403);
        }

        // Must be an accepted booking with a real quoted price, not already paid.
        $status = $booking['status'] ?? 'pending';
        if (!in_array($status, ['accepted', 'session_ready'], true)) {
            return response()->json(['status' => 'error', 'message' => 'Booking is not ready for payment.'], 422);
        }
        if (($booking['payoutStatus'] ?? 'pending') === 'paid') {
            return response()->json(['status' => 'error', 'message' => 'Booking is already paid.'], 422);
        }
        $amount = (float) ($booking['quotedPrice'] ?? 0);
        if ($amount <= 0) {
            return response()->json(['status' => 'error', 'message' => 'Booking has no price to pay.'], 422);
        }

        $params = $this->buildCheckoutParams($bookingId, $booking, $request->user(), $merchantId, $merchantSecret);

        // A short-lived signed URL the app opens in a browser; `redirect()`
        // (below, `signed` middleware) re-derives the params and auto-submits
        // the PayHere form. This is what lets us POST to PayHere without a
        // webview dependency — the app just launches this URL.
        $redirectUrl = URL::temporarySignedRoute(
            'payments.redirect',
            now()->addMinutes(30),
            ['bookingId' => $bookingId]
        );

        return response()->json([
            'status' => 'success',
            'checkout_url' => $this->checkoutUrl(),
            'redirect_url' => $redirectUrl,
            'params' => $params,
        ]);
    }

    /**
     * GET /api/v1/payments/redirect/{bookingId}   (`signed` middleware)
     *
     * Renders a tiny auto-submitting HTML form that POSTs to PayHere. The app
     * opens the signed URL from checkout() in a browser; PayHere then takes
     * over. Signed-URL auth means this can be a plain browser navigation with
     * no Sanctum token, while still being unforgeable.
     */
    public function redirect(Request $request, string $bookingId, FirestoreService $firestore)
    {
        $merchantId = config('services.payhere.merchant_id');
        $merchantSecret = config('services.payhere.merchant_secret');
        if (empty($merchantId) || empty($merchantSecret)) {
            abort(503, 'Payments are not configured.');
        }

        $booking = $firestore->getDocument('booking_requests', $bookingId);
        if (!$booking) {
            abort(404, 'Booking not found.');
        }
        if (($booking['payoutStatus'] ?? 'pending') === 'paid') {
            abort(422, 'Booking is already paid.');
        }
        $amount = (float) ($booking['quotedPrice'] ?? 0);
        if ($amount <= 0) {
            abort(422, 'Booking has no price to pay.');
        }

        // We don't have the Sanctum user here (browser nav), but the signed URL
        // was issued only after checkout() verified ownership — so re-deriving
        // params for a display name is safe; the touristDisplayName snapshot on
        // the booking is enough.
        $params = $this->buildCheckoutParams($bookingId, $booking, null, $merchantId, $merchantSecret);
        $action = $this->checkoutUrl();

        $inputs = '';
        foreach ($params as $key => $value) {
            $inputs .= '<input type="hidden" name="' . e($key) . '" value="' . e((string) $value) . '">' . "\n";
        }

        $html = '<!doctype html><html><head><meta charset="utf-8"><title>Redirecting to payment…</title></head>'
            . '<body onload="document.forms[0].submit()">'
            . '<p>Redirecting you to secure payment…</p>'
            . '<form method="post" action="' . e($action) . '">' . $inputs . '</form>'
            . '</body></html>';

        return response($html)->header('Content-Type', 'text/html');
    }

    private function checkoutUrl(): string
    {
        return config('services.payhere.sandbox')
            ? self::CHECKOUT_URL_SANDBOX
            : self::CHECKOUT_URL_LIVE;
    }

    /**
     * Builds the full PayHere parameter set (including the amount hash) for a
     * booking. Amount/currency come from the booking doc, never the client.
     */
    private function buildCheckoutParams(string $bookingId, array $booking, $user, string $merchantId, string $merchantSecret): array
    {
        $amount = (float) ($booking['quotedPrice'] ?? 0);
        $currency = $booking['currency'] ?? 'LKR';
        $amountFormatted = number_format($amount, 2, '.', '');

        // PayHere amount hash: strtoupper(md5(
        //   merchant_id . order_id . amount . currency .
        //   strtoupper(md5(merchant_secret)) )).
        $hash = strtoupper(md5(
            $merchantId .
            $bookingId .
            $amountFormatted .
            $currency .
            strtoupper(md5($merchantSecret))
        ));

        return [
            'merchant_id' => $merchantId,
            'return_url' => route('payments.return'),
            'cancel_url' => route('payments.cancel'),
            'notify_url' => route('payments.notify'),
            'order_id' => $bookingId,
            'items' => 'Tour booking ' . $bookingId,
            'currency' => $currency,
            'amount' => $amountFormatted,
            'first_name' => ($user->name ?? null) ?: ($booking['touristDisplayName'] ?? 'Traveler'),
            'last_name' => '',
            'email' => ($user->email ?? null) ?: 'traveler@hiddengems.lk',
            'phone' => '',
            'address' => '',
            'city' => 'Colombo',
            'country' => 'Sri Lanka',
            'hash' => $hash,
            'sandbox' => (bool) config('services.payhere.sandbox'),
        ];
    }

    /**
     * POST /api/v1/payments/notify   (server-to-server from PayHere; NO auth)
     *
     * The trusted callback. We verify PayHere's md5sig before believing it,
     * then mark the booking paid via the Admin SDK. Always returns 200 so
     * PayHere doesn't retry-storm on our transient failures (mirrors the
     * RevenueCat webhook's behavior).
     */
    public function notify(Request $request, FirestoreService $firestore)
    {
        $merchantId = config('services.payhere.merchant_id');
        $merchantSecret = config('services.payhere.merchant_secret');

        $paymentId = $request->input('payment_id');
        $orderId = $request->input('order_id');            // == bookingId
        $payhereAmount = $request->input('payhere_amount');
        $payhereCurrency = $request->input('payhere_currency');
        $statusCode = $request->input('status_code');       // '2' == success
        $md5sig = $request->input('md5sig');

        if (empty($merchantSecret)) {
            Log::error('PayHere notify: merchant secret not configured; ignoring.');
            return response('ok', 200);
        }

        // Verify PayHere's signature: strtoupper(md5(
        //   merchant_id . order_id . payhere_amount . payhere_currency .
        //   status_code . strtoupper(md5(merchant_secret)) )).
        $localSig = strtoupper(md5(
            $merchantId .
            $orderId .
            $payhereAmount .
            $payhereCurrency .
            $statusCode .
            strtoupper(md5($merchantSecret))
        ));

        if (!hash_equals($localSig, (string) $md5sig)) {
            Log::warning('PayHere notify: signature mismatch, ignoring.', ['order_id' => $orderId]);
            return response('ok', 200);
        }

        // status_code: 2=success, 0=pending, -1=cancelled, -2=failed, -3=chargedback
        if ((string) $statusCode !== '2') {
            Log::info("PayHere notify: non-success status {$statusCode} for {$orderId}.");
            return response('ok', 200);
        }

        try {
            $booking = $firestore->getDocument('booking_requests', $orderId);
            if (!$booking) {
                Log::warning('PayHere notify: booking not found.', ['order_id' => $orderId]);
                return response('ok', 200);
            }

            // Server is the authoritative source for the commission split.
            $rate = (float) config('services.payhere.commission_rate', 0.10);
            $amount = (float) $payhereAmount;
            $commission = round($amount * $rate, 2);
            $guideNet = round($amount - $commission, 2);

            $firestore->updateBooking($orderId, [
                'payoutStatus' => 'paid',
                'status' => 'confirmed',
                'paidAt' => date('c'),
                'paymentId' => (string) $paymentId,
                'paidAmount' => $amount,
                'commissionAmount' => $commission,
                'guideNetAmount' => $guideNet,
            ]);
            Log::info("PayHere notify: booking {$orderId} marked paid (amount {$amount}, commission {$commission}).");
        } catch (\Exception $e) {
            Log::error('PayHere notify: Firestore update failed', [
                'order_id' => $orderId,
                'error' => $e->getMessage(),
            ]);
        }

        return response('ok', 200);
    }

    /**
     * PayHere redirects the user's browser here after a successful payment.
     * The actual state change happens in notify() (server-to-server) — this is
     * just a friendly landing page; never trust it to confirm payment.
     */
    public function paymentReturn()
    {
        return response()->json(['status' => 'success', 'message' => 'Payment received. Your booking is being confirmed.']);
    }

    /**
     * PayHere redirects here if the user cancels checkout.
     */
    public function paymentCancel()
    {
        return response()->json(['status' => 'cancelled', 'message' => 'Payment was cancelled.']);
    }
}
