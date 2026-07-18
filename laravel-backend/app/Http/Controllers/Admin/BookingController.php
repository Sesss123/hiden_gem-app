<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Services\FirestoreService;
use Illuminate\Http\Request;

class BookingController extends Controller
{
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

        usort($bookings, fn ($a, $b) => strcmp($b['createdAt'] ?? '', $a['createdAt'] ?? ''));

        return view('admin.bookings.index', compact('bookings', 'status'));
    }

    public function show(string $id)
    {
        $booking = $this->firestoreService->getDocument('booking_requests', $id);
        abort_if($booking === null, 404);

        $session = null;
        if (!empty($booking['linkedSessionId'])) {
            $session = $this->firestoreService->getDocument('tour_sessions', $booking['linkedSessionId']);
        }

        return view('admin.bookings.show', compact('booking', 'session'));
    }

    /**
     * Admin-initiated cancellation — used for disputes/no-shows/fraud where
     * neither party cancels through the normal app flow. Mirrors the status
     * value the app itself already understands (cancelled_by_guide is reused
     * here since the app has no dedicated "cancelled_by_admin" status yet;
     * the admin's reason is recorded separately in responseNote).
     */
    public function cancel(Request $request, string $id)
    {
        $request->validate([
            'reason' => 'required|string|max:1000',
        ]);

        $booking = $this->firestoreService->getDocument('booking_requests', $id);
        abort_if($booking === null, 404);

        $this->firestoreService->patchDocument('booking_requests', $id, [
            'status' => 'cancelled_by_guide',
            'responseNote' => '[Admin cancellation] ' . $request->input('reason'),
            'respondedAt' => now()->toIso8601String(),
        ]);

        return redirect()->route('admin.bookings.index', ['status' => $booking['status'] ?? 'pending'])
            ->with('success', 'Booking cancelled by admin.');
    }
}
