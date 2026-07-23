<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Services\FirestoreService;
use Illuminate\Http\Request;

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
    public function index(Request $request)
    {
        $premiumUsers = $this->firestoreService->queryDocuments('users', 'isPremium', 'EQUAL', true);

        // Newest expiry first isn't meaningful without a common reference —
        // sort by plan then name for a stable, scannable list instead.
        usort($premiumUsers, function ($a, $b) {
            $planCmp = strcmp($a['premiumPlan'] ?? '', $b['premiumPlan'] ?? '');
            return $planCmp !== 0 ? $planCmp : strcmp($a['displayName'] ?? '', $b['displayName'] ?? '');
        });

        // Stats (total/plan-breakdown/expiring-soon) are computed over the
        // FULL unfiltered set below, before search narrows the table — a
        // search for one user shouldn't make the "Total Premium Users" card
        // look like the whole premium base shrank.
        $allPremiumUsers = $premiumUsers;

        if ($search = $request->input('search')) {
            $needle = strtolower($search);
            $premiumUsers = array_values(array_filter($premiumUsers, function ($u) use ($needle) {
                return str_contains(strtolower($u['displayName'] ?? ''), $needle)
                    || str_contains(strtolower($u['email'] ?? ''), $needle);
            }));
        }

        $planCounts = [];
        foreach ($allPremiumUsers as $u) {
            $plan = $u['premiumPlan'] ?? 'unknown';
            $planCounts[$plan] = ($planCounts[$plan] ?? 0) + 1;
        }
        arsort($planCounts);

        $now = now();
        $expiringSoonCount = 0;
        foreach ($allPremiumUsers as $u) {
            if (!empty($u['premiumExpiresAt'])) {
                try {
                    $expiresAt = \Carbon\Carbon::parse($u['premiumExpiresAt']);
                    // BUG (found while fixing the identical mistake in
                    // guides/show.blade.php): Carbon's diffInDays() returns a
                    // SIGNED distance in this version — calling it on the
                    // future date with $now as the argument yields a
                    // NEGATIVE number, and "-299 <= 7" is true for every
                    // future date, not just ones actually within 7 days.
                    // now()->diffInDays($expiresAt) gives the correct
                    // unsigned distance.
                    if ($expiresAt->isFuture() && $now->diffInDays($expiresAt) <= 7) {
                        $expiringSoonCount++;
                    }
                } catch (\Exception $e) {
                    // Malformed timestamp on a legacy/manually-edited doc — skip, don't crash the page.
                }
            }
        }

        $totalPremiumCount = count($allPremiumUsers);

        return view('admin.subscriptions.index', compact('premiumUsers', 'planCounts', 'expiringSoonCount', 'totalPremiumCount'));
    }
}
