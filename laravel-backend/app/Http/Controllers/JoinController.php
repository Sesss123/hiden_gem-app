<?php

namespace App\Http\Controllers;

use App\Services\FirestoreService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

/**
 * Public (no-auth) family-sharing "join" page. A tourist generates a link
 * in the app (FamilyShareScreen) and shares the token with a family member
 * who has no account and no app install — so this must be a plain web page,
 * resolved with admin Firestore credentials since firestore.rules only lets
 * the owning tourist (or an active-link viewer bumping viewCount) read
 * family_share_links, and only session participants read tour_sessions.
 */
class JoinController extends Controller
{
    public function show(string $token, FirestoreService $firestore)
    {
        $link = $firestore->getDocument('family_share_links', $token);

        if (!$link) {
            return response()->view('join.invalid', ['reason' => 'not_found'], 404);
        }

        $expiresAt = isset($link['expiresAt']) ? strtotime($link['expiresAt']) : null;
        $isExpired = $expiresAt !== null && $expiresAt < time();

        if (($link['isActive'] ?? false) !== true || $isExpired) {
            return response()->view('join.invalid', ['reason' => 'expired']);
        }

        $permissions = $link['permissions'] ?? [];
        $session = null;
        $guideName = null;

        if (!empty($link['sessionId'])) {
            $session = $firestore->getDocument('tour_sessions', $link['sessionId']);
        }

        if ($session && ($permissions['show_identity'] ?? false) && !empty($session['guideId'])) {
            $guideUser = $firestore->getDocument('users', $session['guideId']);
            $guideName = $guideUser['displayName'] ?? $guideUser['name'] ?? null;
        }

        // Best-effort view count bump (not atomic — acceptable for a
        // display-only counter, and failure here shouldn't block the page).
        try {
            $currentViews = (int) ($link['viewCount'] ?? 0);
            $firestore->patchDocument('family_share_links', $token, ['viewCount' => $currentViews + 1]);
        } catch (\Exception $e) {
            Log::warning('Family share viewCount bump failed', ['token' => $token, 'error' => $e->getMessage()]);
        }

        return view('join.show', [
            'link' => $link,
            'session' => $session,
            'permissions' => $permissions,
            'guideName' => $guideName,
        ]);
    }
}
