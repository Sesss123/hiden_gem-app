<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Services\FirestoreService;
use App\Traits\LogsAdminActivity;
use Illuminate\Http\Request;

class IncidentController extends Controller
{
    use LogsAdminActivity;

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

        // Confirm the incident exists before patching — patchDocument()
        // doesn't itself distinguish "doc not found" from other failures,
        // so this is the only way to give a real 404 for a bad/stale id
        // instead of a false "success" redirect.
        $incident = $this->firestoreService->getDocument('incident_reports', $id);
        abort_if($incident === null, 404);

        $now = now()->toIso8601String();
        $resolvedBy = auth()->user()->name ?? 'admin';
        $resolutionNote = $request->input('resolution_note');

        // Mirrors IncidentRepository.resolveIncident() on the Flutter side:
        // the detail screen's timeline is the only place a reporting user
        // actually reads what happened to their report — resolutionNote is
        // parsed onto the model but never rendered directly, so without a
        // timeline entry an admin resolution was invisible to the user
        // (status flipped to "resolved" with no visible explanation why).
        $timelineEvents = $incident['timelineEvents'] ?? [];
        $timelineEvents[] = [
            'type' => 'resolved',
            'description' => "Incident resolved: {$resolutionNote}",
            'timestamp' => $now,
            'userId' => $resolvedBy,
            'role' => 'admin',
        ];

        $ok = $this->firestoreService->patchDocument('incident_reports', $id, [
            'status' => 'resolved',
            'resolvedAt' => $now,
            'resolvedBy' => $resolvedBy,
            'resolutionNote' => $resolutionNote,
            'timelineEvents' => $timelineEvents,
            'timelineCount' => count($timelineEvents),
            'updatedAt' => $now,
        ]);

        if (!$ok) {
            return back()->withErrors(['error' => 'Could not save the resolution — the update failed. Please try again.']);
        }

        $this->logAdminAction('incident.resolved', 'Incident', $id, ['resolution_note' => $resolutionNote]);

        return redirect()->route('admin.incidents.index', ['status' => 'open'])
            ->with('success', 'Incident marked resolved.');
    }

    /**
     * Dismiss an incident (e.g. duplicate, false alarm) without a full
     * resolution note.
     */
    public function dismiss(string $id)
    {
        $incident = $this->firestoreService->getDocument('incident_reports', $id);
        abort_if($incident === null, 404);

        $now = now()->toIso8601String();
        $resolvedBy = auth()->user()->name ?? 'admin';

        // See resolve() above — same reasoning: without a timeline entry,
        // a dismissed report shows no explanation to the reporting user.
        $timelineEvents = $incident['timelineEvents'] ?? [];
        $timelineEvents[] = [
            'type' => 'dismissed',
            'description' => 'Incident dismissed by admin.',
            'timestamp' => $now,
            'userId' => $resolvedBy,
            'role' => 'admin',
        ];

        $ok = $this->firestoreService->patchDocument('incident_reports', $id, [
            'status' => 'dismissed',
            'timelineEvents' => $timelineEvents,
            'timelineCount' => count($timelineEvents),
            'updatedAt' => $now,
        ]);

        if (!$ok) {
            return back()->withErrors(['error' => 'Could not dismiss the incident — the update failed. Please try again.']);
        }

        $this->logAdminAction('incident.dismissed', 'Incident', $id, []);

        return redirect()->route('admin.incidents.index', ['status' => 'open'])
            ->with('success', 'Incident dismissed.');
    }
}
