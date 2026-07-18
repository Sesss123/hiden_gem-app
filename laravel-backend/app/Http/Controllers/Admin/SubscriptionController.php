<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Services\FirestoreService;

class SubscriptionController extends Controller
{
    private FirestoreService $firestoreService;

    public function __construct()
    {
        $this->firestoreService = new FirestoreService();
    }

    /**
     * Read-only overview of premium users, sourced from Firestore's
     * users/{uid}.isPremium — the real-time field RevenueCatWebhookController
     * is the only trusted writer of (firestore.rules blocks client writes).
     * This is deliberately read-only: there is no grant/revoke action here,
     * since a direct admin override would need its own audit trail and
     * interaction with RevenueCat's own subscription state to avoid drifting
     * out of sync with the next webhook event.
     */
    public function index()
    {
        $premiumUsers = $this->firestoreService->queryDocuments('users', 'isPremium', 'EQUAL', true);

        // Newest expiry first isn't meaningful without a common reference —
        // sort by plan then name for a stable, scannable list instead.
        usort($premiumUsers, function ($a, $b) {
            $planCmp = strcmp($a['premiumPlan'] ?? '', $b['premiumPlan'] ?? '');
            return $planCmp !== 0 ? $planCmp : strcmp($a['displayName'] ?? '', $b['displayName'] ?? '');
        });

        $planCounts = [];
        foreach ($premiumUsers as $u) {
            $plan = $u['premiumPlan'] ?? 'unknown';
            $planCounts[$plan] = ($planCounts[$plan] ?? 0) + 1;
        }
        arsort($planCounts);

        $now = now();
        $expiringSoonCount = 0;
        foreach ($premiumUsers as $u) {
            if (!empty($u['premiumExpiresAt'])) {
                try {
                    $expiresAt = \Carbon\Carbon::parse($u['premiumExpiresAt']);
                    if ($expiresAt->isFuture() && $expiresAt->diffInDays($now) <= 7) {
                        $expiringSoonCount++;
                    }
                } catch (\Exception $e) {
                    // Malformed timestamp on a legacy/manually-edited doc — skip, don't crash the page.
                }
            }
        }

        return view('admin.subscriptions.index', compact('premiumUsers', 'planCounts', 'expiringSoonCount'));
    }
}
