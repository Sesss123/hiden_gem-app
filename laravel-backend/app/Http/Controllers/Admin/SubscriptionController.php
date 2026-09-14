<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Services\FirestoreService;
use App\Traits\LogsAdminActivity;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Carbon\Carbon;

class SubscriptionController extends Controller
{
    use LogsAdminActivity;

    private FirestoreService $firestoreService;

    public const ALLOWED_PLANS = [
        'pro' => 'Guide Pro',
        'elite' => 'Guide Elite',
        'explorer' => 'Explorer',
        'premium' => 'Heritage Premium',
    ];

    public function __construct()
    {
        $this->firestoreService = new FirestoreService();
    }

    /** Missing, malformed, or elapsed entitlement expiries are invalid. */
    public static function hasInvalidExpiry(mixed $value, ?Carbon $now = null): bool
    {
        if ($value === null || trim((string) $value) === '') {
            return true;
        }

        try {
            return Carbon::parse($value)->lte($now ?? Carbon::now());
        } catch (\Throwable $e) {
            return true;
        }
    }

    /**
     * Overview of premium users with automated Integrity Scanner.
     */
    public function index(Request $request)
    {
        $premiumUsers = $this->firestoreService->queryDocuments('users', 'isPremium', 'EQUAL', true);

        // Sort by plan then name for a stable, scannable list
        usort($premiumUsers, function ($a, $b) {
            $planCmp = strcmp($a['premiumPlan'] ?? '', $b['premiumPlan'] ?? '');
            return $planCmp !== 0 ? $planCmp : strcmp($a['displayName'] ?? '', $b['displayName'] ?? '');
        });

        $now = now();
        $invalidOrMockCount = 0;
        $expiringSoonCount = 0;

        // Perform automated integrity check on all premium records
        foreach ($premiumUsers as &$u) {
            $plan = strtolower(trim($u['premiumPlan'] ?? $u['premiumPlanId'] ?? ''));
            $reasons = [];
            if (str_contains($plan, 'mock') || str_contains($plan, 'dev') || !array_key_exists($plan, self::ALLOWED_PLANS)) {
                $reasons[] = 'Unrecognized or development plan';
            }
            $hasExpired = false;
            $isExpiringSoon = false;

            if (!empty($u['premiumExpiresAt'])) {
                try {
                    $expiresAt = Carbon::parse($u['premiumExpiresAt']);
                    if ($expiresAt->isPast()) {
                        $hasExpired = true;
                    } elseif ($now->diffInDays($expiresAt) <= 7) {
                        $isExpiringSoon = true;
                        $expiringSoonCount++;
                    }
                } catch (\Throwable $e) {
                    $hasExpired = true;
                    $reasons[] = 'Malformed expiry timestamp';
                }
            } else {
                $reasons[] = 'Missing subscription expiry';
            }

            if ($hasExpired) $reasons[] = 'Subscription has expired';

            // This record is written only by the authenticated RevenueCat
            // webhook. It is the backend proof that must agree with the user
            // profile; a client-side isPremium flag alone is never sufficient.
            $subscription = $this->firestoreService->findSubscriptionByAccountId((string) ($u['id'] ?? ''));
            $subscriptionPlan = strtolower(trim((string) ($subscription['planId'] ?? '')));
            $subscriptionStatus = strtolower(trim((string) ($subscription['status'] ?? '')));
            if (!$subscription) {
                $reasons[] = 'No trusted webhook subscription record';
            } else {
                if (!in_array($subscriptionStatus, ['active', 'grace_period'], true)) {
                    $reasons[] = 'Webhook subscription is not active';
                }
                if ($subscriptionPlan === '' || $subscriptionPlan !== $plan) {
                    $reasons[] = 'User plan does not match webhook subscription';
                }
            }

            $u['_integrity_reasons'] = array_values(array_unique($reasons));
            $u['_is_mock_or_invalid'] = !empty($u['_integrity_reasons']);
            $u['_is_expired'] = $hasExpired;
            $u['_is_expiring_soon'] = $isExpiringSoon;

            if ($u['_is_mock_or_invalid']) {
                $invalidOrMockCount++;
            }
        }
        unset($u);

        $allPremiumUsers = $premiumUsers;

        if ($search = $request->input('search')) {
            $needle = strtolower($search);
            $premiumUsers = array_values(array_filter($premiumUsers, function ($u) use ($needle) {
                return str_contains(strtolower($u['displayName'] ?? ''), $needle)
                    || str_contains(strtolower($u['email'] ?? ''), $needle)
                    || str_contains(strtolower($u['id'] ?? ''), $needle);
            }));
        }

        $planCounts = [];
        foreach ($allPremiumUsers as $u) {
            if (!empty($u['_is_mock_or_invalid'])) continue;
            $plan = $u['premiumPlan'] ?? 'unknown';
            $planCounts[$plan] = ($planCounts[$plan] ?? 0) + 1;
        }
        arsort($planCounts);

        $totalPremiumCount = count($allPremiumUsers);
        $verifiedPremiumCount = $totalPremiumCount - $invalidOrMockCount;

        return view('admin.subscriptions.index', compact(
            'premiumUsers',
            'planCounts',
            'expiringSoonCount',
            'totalPremiumCount',
            'verifiedPremiumCount',
            'invalidOrMockCount'
        ));
    }

    /**
     * Revoke unverified or mock premium entitlement with full audit trail.
     */
    public function revoke(Request $request, string $uid)
    {
        $user = auth()->user();
        if (!$user || !$user->isFullAdmin()) {
            abort(403, 'Unauthorized. Only Full Administrators can revoke premium entitlements.');
        }

        $request->validate([
            'reason' => 'required|string|max:500',
        ]);

        $reason = $request->input('reason');

        // Fetch existing document to verify previous state
        $existing = $this->firestoreService->getDocument('users', $uid);
        if (!$existing) {
            return back()->with('error', "User {$uid} not found in Firestore.");
        }

        $previousPlan = $existing['premiumPlan'] ?? $existing['premiumPlanId'] ?? 'unknown';
        $normalizedPlan = strtolower(trim((string) $previousPlan));
        $sub = $this->firestoreService->findSubscriptionByAccountId($uid);
        $subPlan = strtolower(trim((string) ($sub['planId'] ?? '')));
        $subStatus = strtolower(trim((string) ($sub['status'] ?? '')));
        $expiryInvalid = self::hasInvalidExpiry($existing['premiumExpiresAt'] ?? null);
        $isInvalid = !array_key_exists($normalizedPlan, self::ALLOWED_PLANS)
            || !$sub
            || $subPlan !== $normalizedPlan
            || !in_array($subStatus, ['active', 'grace_period'], true)
            || $expiryInvalid;
        if (!$isInvalid) {
            return back()->withErrors(['subscription' => 'This entitlement matches an active webhook subscription and cannot be removed by the anomaly-cleanup action. Cancel it through RevenueCat first.']);
        }

        $this->logAdminAction('subscription.revoke_requested', 'User', $uid, [
            'previous_plan' => $previousPlan,
            'reason' => $reason,
        ]);

        $userUpdate = [
            'isPremium' => false,
            'premiumPlan' => null,
            'premiumPlanId' => null,
            'premiumExpiresAt' => null,
            'autoRenew' => false,
            'revokedAt' => now()->toIso8601String(),
            'revokedBy' => $user->email,
            'revocationReason' => $reason,
        ];
        $writes = [[
            'collection' => 'users', 'id' => $uid, 'data' => $userUpdate,
            'updateMask' => array_keys($userUpdate), 'exists' => true,
        ]];
        if ($sub && !empty($sub['id'])) {
            $subUpdate = ['status' => 'revoked_by_admin', 'autoRenew' => false, 'revokedAt' => now()->toIso8601String()];
            $writes[] = [
                'collection' => 'subscriptions', 'id' => $sub['id'], 'data' => $subUpdate,
                'updateMask' => array_keys($subUpdate), 'exists' => true,
            ];
        }
        try {
            $committed = $this->firestoreService->commitDocuments($writes);
        } catch (\Throwable $e) {
            $committed = false;
        }
        if (!$committed) {
            $this->logAdminAction('subscription.revoke_failed', 'User', $uid, ['reason' => $reason]);
            return back()->withErrors(['subscription' => "Failed revoking subscription for {$uid}; Firestore made no changes."]);
        }

        // Firestore and MySQL cannot share a transaction. The earlier
        // revoke_requested entry guarantees a durable intent record; report
        // final-audit failure truthfully instead of showing a false success.
        try {
            $this->logAdminAction(
                'subscription.revoked',
                'User',
                $uid,
                [
                    'previous_plan' => $previousPlan,
                    'reason' => $reason,
                    'target_uid' => $uid,
                    'admin_email' => $user->email,
                ]
            );
        } catch (\Throwable $e) {
            Log::critical('Premium entitlement was revoked but the final audit entry failed.', [
                'target_uid' => $uid,
                'admin_id' => $user->id,
                'error' => $e->getMessage(),
            ]);
            return back()->withErrors([
                'subscription' => "Premium was revoked for {$uid}, but the final audit entry failed. The earlier revoke request remains logged; investigate the server log.",
            ]);
        }

        return back()->with('success', "Premium subscription successfully revoked for UID: {$uid} (Audit logged).");
    }
}
