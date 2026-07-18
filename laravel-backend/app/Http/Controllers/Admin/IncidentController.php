<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Services\FirestoreService;
use Illuminate\Http\Request;

class IncidentController extends Controller
{
    private FirestoreService $firestoreService;

    public function __construct()
    {
        $this->firestoreService = new FirestoreService();
    }

    /**
     * List incident reports (SOS alerts + manual reports) from Firestore,
     * filtered by status. Mirrors the app's own status vocabulary:
     * open, under_review, escalated, resolved, dismissed.
     */
    public function index(Request $request)
    {
        $status = $request->input('status', 'open');

        $incidents = $status === 'all'
            ? $this->firestoreService->listDocuments('incident_reports')
            : $this->firestoreService->queryDocuments('incident_reports', 'status', 'EQUAL', $status);

        // Newest first — createdAt is stored as an ISO8601 string by the app.
        usort($incidents, fn ($a, $b) => strcmp($b['createdAt'] ?? '', $a['createdAt'] ?? ''));

        return view('admin.incidents.index', compact('incidents', 'status'));
    }

    public function show(string $id)
    {
        $incident = $this->firestoreService->getDocument('incident_reports', $id);
        abort_if($incident === null, 404);

        return view('admin.incidents.show', compact('incident'));
    }

    /**
     * Resolve an incident with a note. Mirrors
     * IncidentRepository.resolveIncident() on the Flutter side, but run from
     * the admin's own MySQL-authenticated identity (name) rather than a
     * Firebase UID, since admin accounts don't necessarily have one.
     */
    public function resolve(Request $request, string $id)
    {
        $request->validate([
            'resolution_note' => 'required|string|max:1000',
        ]);

        $now = now()->toIso8601String();
        $resolvedBy = auth()->user()->name ?? 'admin';

        $this->firestoreService->patchDocument('incident_reports', $id, [
            'status' => 'resolved',
            'resolvedAt' => $now,
            'resolvedBy' => $resolvedBy,
            'resolutionNote' => $request->input('resolution_note'),
            'updatedAt' => $now,
        ]);

        return redirect()->route('admin.incidents.index', ['status' => 'open'])
            ->with('success', 'Incident marked resolved.');
    }

    /**
     * Dismiss an incident (e.g. duplicate, false alarm) without a full
     * resolution note.
     */
    public function dismiss(string $id)
    {
        $this->firestoreService->patchDocument('incident_reports', $id, [
            'status' => 'dismissed',
            'updatedAt' => now()->toIso8601String(),
        ]);

        return redirect()->route('admin.incidents.index', ['status' => 'open'])
            ->with('success', 'Incident dismissed.');
    }
}
