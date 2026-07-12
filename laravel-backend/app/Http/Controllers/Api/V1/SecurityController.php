<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\FirestoreService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class SecurityController extends Controller
{
    /**
     * GET /v1/security/device-account-count?deviceHash=...
     *
     * Counts distinct accounts bound to a device hash, for
     * DeviceTrustGraph's multi-account-per-device fraud check. Runs
     * server-side because firestore.rules only allows admins to read the
     * device_trust collection directly — a regular client can write its own
     * binding but can never query other users' bindings, so this specific
     * count has to be resolved here with admin Firestore credentials.
     */
    public function deviceAccountCount(Request $request, FirestoreService $firestore)
    {
        $deviceHash = $request->query('deviceHash');
        if (!$deviceHash) {
            return response()->json(['error' => 'deviceHash is required'], 422);
        }

        // Security: the legitimate caller (DeviceTrustGraph.recordAndVerifyLogin)
        // always queries its OWN device's hash, right after binding it — never
        // an arbitrary one. Without this check, any authenticated user could
        // pass any deviceHash and learn account-count fraud signals about a
        // device they don't own, bypassing the admin-only Firestore rule this
        // endpoint exists to bridge around. Requiring the caller's own binding
        // to already exist confirms they're asking about their own device.
        $callerUid = (string) $request->user()->firebase_uid;
        $ownBinding = $firestore->getDocument('device_trust', "{$deviceHash}_{$callerUid}");
        if (!$ownBinding) {
            return response()->json(['error' => 'No binding found for this device and caller.'], 403);
        }

        try {
            $bindings = $firestore->queryDocuments('device_trust', 'deviceHash', 'EQUAL', $deviceHash);
            $distinctAccounts = collect($bindings)->pluck('uid')->unique()->count();

            return response()->json(['accountCount' => $distinctAccounts]);
        } catch (\Exception $e) {
            Log::error('Device account count failed', ['device_hash' => $deviceHash, 'error' => $e->getMessage()]);
            return response()->json(['error' => 'Failed to check device account count'], 500);
        }
    }
}
