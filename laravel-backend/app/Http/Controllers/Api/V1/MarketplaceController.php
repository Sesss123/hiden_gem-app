<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\FirestoreService;
use Illuminate\Support\Facades\Cache;

class MarketplaceController extends Controller
{
    /**
     * GET /v1/listings/featured
     *
     * Cached (5 min) read of published, approved, featured guide listings,
     * highest-rated first, capped at 10. Previously the Flutter client
     * queried guide_listings directly from Firestore on every marketplace
     * screen open (mitigated only by a 5-min client-local cache per device)
     * — this adds a shared server-side cache so the whole app's traffic
     * within the cache window costs 1 Firestore read instead of 1 per device.
     *
     * The 'listings_featured' cache key is also kept warm by the
     * marketplace:broadcast-updates scheduled command (App\Console\Commands\
     * BroadcastMarketplaceUpdates), which additionally fires a Reverb
     * broadcast on the `featured-listings` channel when the data changes —
     * this endpoint's Cache::remember() below only runs its callback on a
     * cold/expired cache, so it does not add extra Firestore reads on top.
     */
    public function featured(FirestoreService $firestore)
    {
        $listings = Cache::remember('listings_featured', 300, function () use ($firestore) {
            $all = $firestore->queryDocuments('guide_listings', 'isFeatured', 'EQUAL', true);
            $filtered = array_values(array_filter($all, fn ($l) =>
                ($l['status'] ?? '') === 'published' && ($l['moderationStatus'] ?? '') === 'approved'
            ));
            usort($filtered, fn ($a, $b) => ($b['ratingAverage'] ?? 0) <=> ($a['ratingAverage'] ?? 0));
            return array_slice($filtered, 0, 10);
        });

        return response()->json(['listings' => $listings]);
    }

    /**
     * GET /v1/ar/enabled-locations
     *
     * Cached (10 min) list of `locations` docs that have a non-empty
     * videoUrl. Previously the Flutter client's AR Video Library screen ran
     * ARVideoRepository::getAllEnabled() — a full collection scan of
     * `locations` — directly against Firestore on every screen open, with no
     * shared cache. AR-enabled locations only change when an admin adds new
     * AR content, so a 10-min server cache turns every view within the
     * window into 1 shared Firestore read instead of 1-per-device.
     *
     * The 'ar_enabled_locations' cache key is also kept warm by the
     * marketplace:broadcast-updates scheduled command, which additionally
     * fires a Reverb broadcast on the `ar-enabled-locations` channel when
     * the data changes — see the note on featured() above.
     */
    public function arEnabledLocations(FirestoreService $firestore)
    {
        $locations = Cache::remember('ar_enabled_locations', 600, function () use ($firestore) {
            $all = $firestore->listDocuments('locations');
            return array_values(array_filter($all, fn ($l) => !empty($l['videoUrl'] ?? '')));
        });

        return response()->json(['locations' => $locations]);
    }
}
