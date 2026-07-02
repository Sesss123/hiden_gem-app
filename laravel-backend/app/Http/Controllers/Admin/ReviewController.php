<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Place;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class ReviewController extends Controller
{
    /**
     * Display pending places waiting for admin review.
     */
    public function index()
    {
        $pendingPlaces = Place::where('status', 'pending')
            ->orderBy('created_at', 'asc')
            ->paginate(15);

        $pendingCount = Place::where('status', 'pending')->count();

        return view('admin.reviews.index', compact('pendingPlaces', 'pendingCount'));
    }

    /**
     * Approve a pending place.
     */
    public function approve($id)
    {
        $place = Place::findOrFail($id);
        $place->update([
            'status' => 'approved',
            'reviewed_by' => Auth::id() ?? 1,
        ]);

        return redirect()->route('admin.reviews.index')
            ->with('success', "Place '{$place->name}' has been approved and published to mobile synchronization!");
    }

    /**
     * Reject a pending place with a reason.
     */
    public function reject(Request $request, $id)
    {
        $request->validate([
            'review_reason' => 'required|string|max:1000',
        ]);

        $place = Place::findOrFail($id);
        $place->update([
            'status' => 'rejected',
            'reviewed_by' => Auth::id() ?? 1,
            'review_reason' => $request->review_reason,
        ]);

        return redirect()->route('admin.reviews.index')
            ->with('success', "Place '{$place->name}' has been rejected.");
    }
}
