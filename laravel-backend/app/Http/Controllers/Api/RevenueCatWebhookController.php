<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\FirestoreService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class RevenueCatWebhookController extends Controller
{
    /**
     * Maps RevenueCat product identifiers (configured in subscription_service.dart)
     * back to our internal plan IDs.
     */
    private const PRODUCT_TO_PLAN = [
        'guide_pro_monthly' => 'pro',
        'guide_elite_monthly' => 'elite',
    ];

    /**
     * Event types that mean the subscription is currently active.
     */
    private const ACTIVE_EVENT_TYPES = ['INITIAL_PURCHASE', 'RENEWAL', 'UNCANCELLATION', 'PRODUCT_CHANGE'];

    /**
     * Event type that means the user cancelled auto-renew but is still
     * entitled until expiry (RevenueCat sends a separate EXPIRATION event later).
     */
    private const CANCELLATION_EVENT_TYPE = 'CANCELLATION';

    /**
     * Event type that means the subscription has actually lapsed.
     */
    private const EXPIRATION_EVENT_TYPE = 'EXPIRATION';

    /**
     * POST /api/webhooks/revenuecat
     *
     * Trusted server-to-server callback from RevenueCat. This is the ONLY
     * path allowed to elevate 'isPremium' on a user's Firestore document —
     * firestore.rules explicitly blocks clients from setting this field
     * themselves (see users/{userId} rule), since the client previously
     * tried to do this directly and the write silently failed.
     *
     * This replaces the equivalent 'revenuecat_webhook' Cloud Function
     * (functions/index.ts) — moved here to avoid Cloud Functions invocation/
     * Firestore-read billing, now that Laravel already runs on a VPS.
     * Point RevenueCat's dashboard webhook URL at this endpoint instead, and
     * disable the Cloud Function version to avoid double-processing events.
     */
    public function handle(Request $request, FirestoreService $firestore)
    {
        $payload = $request->input('event', []);
        $eventType = $payload['type'] ?? null;
        $appUserId = $payload['app_user_id'] ?? null;
        $productId = $payload['product_id'] ?? null;
        $expirationAtMs = $payload['expiration_at_ms'] ?? null;

        if (!$eventType || !$appUserId) {
            Log::warning('RevenueCat webhook: missing event.type or event.app_user_id', ['payload' => $payload]);
            // Acknowledge anyway — malformed/irrelevant events shouldn't be retried forever.
            return response()->json(['status' => 'ignored']);
        }

        $planId = self::PRODUCT_TO_PLAN[$productId] ?? null;
        $expiresAt = $expirationAtMs ? date('c', (int) ($expirationAtMs / 1000)) : null;

        try {
            // Determine which account this subscription belongs to. Mirrors the
            // Cloud Function's lookup: prefer an existing subscriptions/{id} record
            // (keyed by accountId == appUserId) to learn accountType; otherwise probe
            // 'users' then 'operator_accounts' for a matching document.
            [$collection, $accountType, $subscriptionId] = $this->resolveAccount($firestore, $appUserId);

            $subUpdate = [
                'accountId' => $appUserId,
                'accountType' => $accountType,
            ];

            if (in_array($eventType, self::ACTIVE_EVENT_TYPES, true)) {
                $firestore->patchDocument($collection, $appUserId, array_filter([
                    'isPremium' => true,
                    'premiumPlanId' => $planId,
                    'premiumPlan' => $planId,
                    'premiumExpiresAt' => $expiresAt,
                    'autoRenew' => true,
                    'subscriptionPlan' => $planId,
                    'subExpiresAt' => $expiresAt,
                ], fn ($v) => $v !== null));

                $subUpdate = array_merge($subUpdate, array_filter([
                    'status' => 'active',
                    'autoRenew' => true,
                    'planId' => $planId,
                    'expiresAt' => $expiresAt,
                ], fn ($v) => $v !== null));
            } elseif ($eventType === self::CANCELLATION_EVENT_TYPE) {
                // Still entitled until expiry — only flip autoRenew off.
                $firestore->patchDocument($collection, $appUserId, ['autoRenew' => false]);
                $subUpdate['status'] = 'cancelled';
                $subUpdate['autoRenew'] = false;
                $subUpdate['cancelledAt'] = date('c');
            } elseif ($eventType === self::EXPIRATION_EVENT_TYPE) {
                $firestore->patchDocument($collection, $appUserId, [
                    'isPremium' => false,
                    'autoRenew' => false,
                ]);
                $subUpdate['status'] = 'expired';
                $subUpdate['autoRenew'] = false;
            } else {
                Log::info("RevenueCat webhook: unhandled event type '{$eventType}', ignoring.", ['app_user_id' => $appUserId]);
                return response()->json(['status' => 'ok']);
            }

            $firestore->updateSubscriptionRecord($subscriptionId, $subUpdate);
        } catch (\Exception $e) {
            // Log and still return 200 — a transient Firestore failure shouldn't
            // trigger RevenueCat's retry storm; investigate via logs instead.
            Log::error('RevenueCat webhook: Firestore update failed', [
                'app_user_id' => $appUserId,
                'event_type' => $eventType,
                'error' => $e->getMessage(),
            ]);
        }

        return response()->json(['status' => 'ok']);
    }

    /**
     * Resolves [collection, accountType, subscriptionId] for the given RevenueCat
     * app_user_id, mirroring the Cloud Function's lookup order:
     *   1. An existing subscriptions/{id} doc with accountId == appUserId.
     *   2. Otherwise, probe users/{appUserId} then operator_accounts/{appUserId}.
     * Falls back to 'users'/'guide' with a fresh subscription id if nothing matches
     * (first-ever event for this user).
     */
    private function resolveAccount(FirestoreService $firestore, string $appUserId): array
    {
        $existing = $firestore->findSubscriptionByAccountId($appUserId);
        if ($existing !== null) {
            $accountType = $existing['accountType'] ?? 'guide';
            $collection = $accountType === 'guide' ? 'users' : 'operator_accounts';
            return [$collection, $accountType, $existing['id']];
        }

        if ($firestore->documentExists('users', $appUserId)) {
            return ['users', 'guide', $appUserId];
        }
        if ($firestore->documentExists('operator_accounts', $appUserId)) {
            return ['operator_accounts', 'operator', $appUserId];
        }

        // Unknown account — default to 'users'/'guide' so the webhook still
        // records something rather than silently dropping the event.
        return ['users', 'guide', $appUserId];
    }
}
