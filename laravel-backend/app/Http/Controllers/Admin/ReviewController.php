<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Services\FirestoreService;
use App\Traits\LogsAdminActivity;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;

class ReviewController extends Controller
{
    use LogsAdminActivity;

    private FirestoreService $firestoreService;

    public function __construct()
    {
        $this->firestoreService = new FirestoreService();
    }

    /**
     * List tour_reviews from Firestore, filtered by moderationStatus (mirrors
     * TourReview.moderationStatus on the Flutter side: active, flagged,
     * hidden, under_review). Defaults to 'flagged' — the actionable queue —
     * rather than 'active', since most reviews need no admin attention.
     */
    public function index(Request $request)
    {
        $status = $request->input('status', 'flagged');

        $reviews = $status === 'all'
            ? $this->firestoreService->listDocuments('tour_reviews')
            : $this->firestoreService->queryDocuments('tour_reviews', 'moderationStatus', 'EQUAL', $status);

        usort($reviews, fn ($a, $b) => strcmp($b['createdAt'] ?? '', $a['createdAt'] ?? ''));

        return view('admin.reviews.index', compact('reviews', 'status'));
    }

    /**
     * Hide a review (soft-moderation — the app's own ReviewRepository reads
     * only moderationStatus == 'active' via ReviewController::guideReviews,
     * so a hidden review simply stops appearing without deleting the record).
     * Also invalidates the guide's write-through review cache and recomputes
     * reviewCount/ratingAverage so the change reflects immediately.
     */
    public function hide(Request $request, string $id)
    {
        $request->validate([
            'reason' => 'required|string|max:500',
        ]);

        $review = $this->firestoreService->getDocument('tour_reviews', $id);
        abort_if($review === null, 404);

        $ok = $this->firestoreService->patchDocument('tour_reviews', $id, [
            'moderationStatus' => 'hidden',
            'hiddenByAdmin' => auth()->user()->name ?? 'admin',
            'hiddenReason' => $request->input('reason'),
        ]);

        if (!$ok) {
            return back()->withErrors(['error' => 'Could not hide the review — the update failed. Please try again.']);
        }

        $this->recalculateGuideStats($review['guideId'] ?? null);
        $this->logAdminAction('review.hidden', 'Review', $id, ['reason' => $request->input('reason')]);

        return redirect()->route('admin.reviews.index', ['status' => 'flagged'])
            ->with('success', 'Review hidden from public view.');
    }

    /**
     * Restore a previously hidden/flagged review back to active.
     */
    public function restore(string $id)
    {
        $review = $this->firestoreService->getDocument('tour_reviews', $id);
        abort_if($review === null, 404);

        $ok = $this->firestoreService->patchDocument('tour_reviews', $id, [
            'moderationStatus' => 'active',
            'hiddenByAdmin' => null,
            'hiddenReason' => null,
        ]);

        if (!$ok) {
            return back()->withErrors(['error' => 'Could not restore the review — the update failed. Please try again.']);
        }

        $this->recalculateGuideStats($review['guideId'] ?? null);
        $this->logAdminAction('review.restored', 'Review', $id, []);

        return redirect()->route('admin.reviews.index', ['status' => 'flagged'])
            ->with('success', 'Review restored to active.');
    }

    /**
     * Recomputes a guide's reviewCount/ratingAverage from active reviews and
     * refreshes the same write-through cache key ReviewController::recalculate
     * (the app-facing API) uses — see that controller's class doc. Kept
     * duplicated rather than shared because the app-facing endpoint requires
     * a Sanctum-authenticated review owner, which doesn't apply here.
     */
    private function recalculateGuideStats(?string $guideId): void
    {
        if (!$guideId) {
            return;
        }

        $all = $this->firestoreService->queryDocuments('tour_reviews', 'guideId', 'EQUAL', $guideId);
        $active = array_values(array_filter($all, fn ($r) => ($r['moderationStatus'] ?? 'active') === 'active'));
        usort($active, fn ($a, $b) => strcmp($b['createdAt'] ?? '', $a['createdAt'] ?? ''));

        Cache::put("reviews_guide_{$guideId}", array_slice($active, 0, 50), 60 * 60 * 24);

        $count = count($active);
        $average = $count > 0
            ? array_sum(array_map(fn ($r) => (float) ($r['overallRating'] ?? 0), $active)) / $count
            : 0.0;

        $this->firestoreService->updateGuideUser($guideId, [
            'reviewCount' => $count,
            'ratingAverage' => round($average, 2),
        ]);
    }
}
