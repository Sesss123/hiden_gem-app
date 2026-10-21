<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Services\FirestoreService;
use App\Traits\LogsAdminActivity;
use Illuminate\Http\Request;

class SafetyReportController extends Controller
{
    use LogsAdminActivity;

    private FirestoreService $firestoreService;

    public function __construct()
    {
        $this->firestoreService = new FirestoreService();
    }

    public function index(Request $request)
    {
        $status = $request->input('status', 'pending');
        abort_unless(in_array($status, ['pending', 'resolved', 'dismissed', 'all'], true), 422);

        $reports = array_merge(
            $this->reportsFor('abuse_reports', 'User/content', $status),
            $this->reportsFor('ai_output_reports', 'AI output', $status),
        );
        usort($reports, fn ($a, $b) => strcmp($b['createdAt'] ?? '', $a['createdAt'] ?? ''));

        return view('admin.safety-reports.index', compact('reports', 'status'));
    }

    public function update(Request $request, string $type, string $id)
    {
        $data = $request->validate([
            'status' => 'required|in:resolved,dismissed',
            'resolution_note' => 'nullable|string|max:500',
        ]);
        $collection = $this->collectionFor($type);
        abort_if($this->firestoreService->getDocument($collection, $id) === null, 404);

        $ok = $this->firestoreService->patchDocument($collection, $id, [
            'status' => $data['status'],
            'resolutionNote' => trim($data['resolution_note'] ?? ''),
            'reviewedAt' => now()->toIso8601String(),
            'reviewedBy' => (string) auth()->id(),
        ]);
        if (!$ok) {
            return back()->withErrors(['error' => 'The report could not be updated. Please try again.']);
        }

        $this->logAdminAction('safety_report.' . $data['status'], 'SafetyReport', $id, [
            'collection' => $collection,
        ]);

        return redirect()->route('admin.safety-reports.index')
            ->with('success', 'Safety report marked ' . $data['status'] . '.');
    }

    private function reportsFor(string $collection, string $label, string $status): array
    {
        $reports = $status === 'all'
            ? $this->firestoreService->listDocuments($collection)
            : $this->firestoreService->queryDocuments($collection, 'status', 'EQUAL', $status);

        return array_map(function (array $report) use ($collection, $label) {
            $report['collection'] = $collection;
            $report['typeLabel'] = $label;
            return $report;
        }, $reports);
    }

    private function collectionFor(string $type): string
    {
        return match ($type) {
            'abuse' => 'abuse_reports',
            'ai' => 'ai_output_reports',
            default => abort(404),
        };
    }
}
