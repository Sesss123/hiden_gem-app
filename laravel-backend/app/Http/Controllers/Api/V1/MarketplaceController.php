<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\FirestoreService;
use Illuminate\Support\Facades\Cache;
use Illuminate\Http\Request;

class MarketplaceController extends Controller
{
    /** Paginated, case-insensitive marketplace text/filter search. */
    public function search(Request $request, FirestoreService $firestore)
    {
        $validated = $request->validate([
            'q' => 'required|string|min:2|max:100',
            'region' => 'nullable|string|max:100',
            'category' => 'nullable|string|max:100',
            'language' => 'nullable|string|max:100',
            'vehicle' => 'nullable|boolean',
            'tour_type' => 'nullable|in:doesBoatSafari,doesWildlifeSafari,doesHiking,doesDiving,doesCulturalTours',
            'page' => 'nullable|integer|min:1|max:500',
        ]);

        $needle = mb_strtolower(trim($validated['q']));
        $all = $firestore->listDocuments('guide_listings');
        $filtered = array_values(array_filter($all, function ($listing) use ($validated, $needle) {
            if (($listing['status'] ?? '') !== 'published' || ($listing['moderationStatus'] ?? '') !== 'approved') return false;
            $haystack = mb_strtolower(implode(' ', array_filter([
                $listing['displayName'] ?? '', $listing['bio'] ?? '', $listing['guideCategory'] ?? '',
                implode(' ', $listing['regions'] ?? []), implode(' ', $listing['languages'] ?? []),
                implode(' ', $listing['specializations'] ?? []),
            ])));
            if (!str_contains($haystack, $needle)) return false;
            if (!empty($validated['region']) && !in_array($validated['region'], $listing['regions'] ?? [], true)) return false;
            if (!empty($validated['category']) && ($listing['guideCategory'] ?? null) !== $validated['category']) return false;
            if (!empty($validated['language']) && !in_array($validated['language'], $listing['languages'] ?? [], true)) return false;
            if (($validated['vehicle'] ?? false) && ($listing['vehicleAvailable'] ?? false) !== true) return false;
            if (!empty($validated['tour_type']) && ($listing[$validated['tour_type']] ?? false) !== true) return false;
            return true;
        }));
        usort($filtered, fn ($a, $b) => ($b['ratingAverage'] ?? 0) <=> ($a['ratingAverage'] ?? 0));

        $page = (int) ($validated['page'] ?? 1);
        $perPage = 20;
        $offset = ($page - 1) * $perPage;
        $items = array_slice($filtered, $offset, $perPage);
        return response()->json([
            'listings' => $items,
            'has_more' => $offset + count($items) < count($filtered),
            'next_page' => $offset + count($items) < count($filtered) ? $page + 1 : null,
        ]);
    }

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
