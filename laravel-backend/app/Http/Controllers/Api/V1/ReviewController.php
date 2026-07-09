<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\FirestoreService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;

class ReviewController extends Controller
{
    private const CACHE_TTL_SECONDS = 60 * 60 * 24; // 24h safety net — see class doc.

    /**
     * GET /v1/reviews/guide/{guideId}
     *
     * WRITE-THROUGH CACHE: this cache is normally kept fresh by recalculate()
     * below, which already reads this guide's reviews from Firestore on every
     * new submission (to compute reviewCount/ratingAverage) and reuses that
     * same read to rebuild this cache — so a Firestore read only happens when
     * a review is actually submitted, never when a profile is merely viewed.
     * The 24h TTL here is just a safety net (e.g. if the cache store was
     * cleared) — it is NOT the primary refresh mechanism.
     */
    public function guideReviews(string $guideId, FirestoreService $firestore)
    {
        $reviews = Cache::remember(
            "reviews_guide_{$guideId}",
            self::CACHE_TTL_SECONDS,
            fn () => array_slice($this->fetchActiveReviews($guideId, $firestore), 0, 50)
        );

        return response()->json(['reviews' => $reviews]);
    }

    /**
     * Reads ALL of a guide's reviews from Firestore and filters to active,
     * sorted newest-first. Unbounded — callers that only need a display page
     * must slice the result themselves (see guideReviews()); recalculate()
     * below needs the full, uncapped list to compute an accurate count/average.
     */
    private function fetchActiveReviews(string $guideId, FirestoreService $firestore): array
    {
        $all = $firestore->queryDocuments('tour_reviews', 'guideId', 'EQUAL', $guideId);
        $active = array_values(array_filter($all, fn ($r) => ($r['moderationStatus'] ?? 'active') === 'active'));
        usort($active, fn ($a, $b) => strcmp($b['createdAt'] ?? '', $a['createdAt'] ?? ''));
        return $active;
    }

    /**
     * POST /v1/reviews/{reviewId}/recalculate
     *
     * Trusted server-side path for updating a guide's reviewCount and
     * ratingAverage after a new review is submitted. firestore.rules blocks
     * a tourist's client from writing these fields on the guide's user
     * document directly (see users/{userId} rule), so the client calls this
     * endpoint right after successfully creating the tour_reviews document.
     *
     * This is also where the guideReviews() cache gets refreshed (write-through
     * — see class doc): the Firestore read below is already required to
     * compute an accurate rating average, so rebuilding the reviews cache from
     * the same data costs nothing extra.
     */
    public function recalculate(Request $request, string $reviewId, FirestoreService $firestore)
    {
        $guideId = $request->input('guideId');
        if (!$guideId) {
            return response()->json(['error' => 'guideId is required'], 422);
        }

        // Pull ALL active reviews for this guide (unbounded — needed for an
        // accurate count/average) and refresh the guideReviews() display
        // cache (capped at 50) from this same read (write-through).
        $activeReviews = $this->fetchActiveReviews($guideId, $firestore);
        Cache::put("reviews_guide_{$guideId}", array_slice($activeReviews, 0, 50), self::CACHE_TTL_SECONDS);

        $count = count($activeReviews);
        $average = $count > 0
            ? array_sum(array_map(fn ($r) => (float) ($r['overallRating'] ?? 0), $activeReviews)) / $count
            : 0.0;

        try {
            $firestore->updateGuideUser($guideId, [
                'reviewCount' => $count,
                'ratingAverage' => round($average, 2),
            ]);
        } catch (\Exception $e) {
            Log::error('Review recalculate: Firestore update failed', [
                'guide_id' => $guideId,
                'review_id' => $reviewId,
                'error' => $e->getMessage(),
            ]);
            return response()->json(['error' => 'Failed to update guide stats'], 500);
        }

        return response()->json(['status' => 'ok', 'reviewCount' => $count, 'ratingAverage' => round($average, 2)]);
    }
}
