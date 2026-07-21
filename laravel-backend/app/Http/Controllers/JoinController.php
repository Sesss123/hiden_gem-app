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
 * family_share_links.
 *
 * The tour status shown on this page (phase, guide name, meeting point,
 * SOS) is end-to-end encrypted: the tourist's device encrypts it with a
 * per-link key that only ever travels in the share URL's fragment, which
 * browsers never send to any server. This controller therefore no longer
 * reads tour_sessions/users at all — it only ever sees/passes ciphertext
 * (`encryptedStatus`), decrypted client-side in show.blade.php via
 * WebCrypto. Laravel structurally cannot leak plaintext status.
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
            'encryptedStatus' => $link['encryptedStatus'] ?? null,
        ]);
    }
}
