<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Services\FirestoreService;
use App\Traits\LogsAdminActivity;
use Carbon\CarbonImmutable;
use Illuminate\Http\Request;

class FamilyShareController extends Controller
{
    use LogsAdminActivity;

    public function __construct(private FirestoreService $firestoreService)
    {
    }

    public function index(Request $request)
    {
        $links = $this->firestoreService->listDocuments('family_share_links');
        $now = CarbonImmutable::now('UTC');

        foreach ($links as &$link) {
            try {
                $link['_expiresAt'] = !empty($link['expiresAt'])
                    ? CarbonImmutable::parse($link['expiresAt'])->utc()
                    : null;
            } catch (\Throwable $e) {
                $link['_expiresAt'] = null;
            }
            try {
                $link['_lastSyncedAt'] = !empty($link['lastSyncedAt'])
                    ? CarbonImmutable::parse($link['lastSyncedAt'])->utc()
                    : null;
            } catch (\Throwable $e) {
                $link['_lastSyncedAt'] = null;
            }
            $link['_expired'] = $link['_expiresAt'] === null || $link['_expiresAt']->isPast();
            $link['_active'] = ($link['isActive'] ?? false) === true && !$link['_expired'];
            $link['_stale'] = $link['_active'] &&
                ($link['_lastSyncedAt'] === null || $link['_lastSyncedAt']->lt($now->subMinutes(2)));
        }
        unset($link);

        $allLinks = $links;
        if ($search = trim((string) $request->input('search'))) {
            $needle = strtolower($search);
            $links = array_values(array_filter($links, fn ($link) =>
                str_contains(strtolower((string) ($link['recipientName'] ?? '')), $needle) ||
                str_contains(strtolower((string) ($link['touristId'] ?? '')), $needle) ||
                str_contains(strtolower((string) ($link['sessionId'] ?? '')), $needle)
            ));
        }
        if ($status = $request->input('status')) {
            $links = array_values(array_filter($links, fn ($link) => match ($status) {
                'active' => $link['_active'],
                'stale' => $link['_stale'],
                'inactive' => !$link['_active'],
                default => true,
            }));
        }

        usort($links, fn ($a, $b) => ($b['_expiresAt']?->getTimestamp() ?? 0) <=> ($a['_expiresAt']?->getTimestamp() ?? 0));

        return view('admin.family-share.index', [
            'links' => $links,
            'totalCount' => count($allLinks),
            'activeCount' => count(array_filter($allLinks, fn ($link) => $link['_active'])),
            'staleCount' => count(array_filter($allLinks, fn ($link) => $link['_stale'])),
        ]);
    }

    public function revoke(string $shareId)
    {
        if (!preg_match('/^[A-HJ-NP-Z2-9]{26}$/', $shareId)) {
            abort(404);
        }

        $link = $this->firestoreService->getDocument('family_share_links', $shareId);
        if (!$link) {
            return back()->withErrors(['share' => 'Family Share link was not found.']);
        }

        if (!$this->firestoreService->patchDocument('family_share_links', $shareId, ['isActive' => false])) {
            return back()->withErrors(['share' => 'Link could not be revoked. Firestore did not confirm the update.']);
        }

        $this->logAdminAction('family_share_revoked', 'family_share_link', $shareId, [
            'touristId' => $link['touristId'] ?? null,
            'sessionId' => $link['sessionId'] ?? null,
            'recipientName' => $link['recipientName'] ?? null,
        ]);

        return back()->with('success', 'Family Share access revoked.');
    }
}
