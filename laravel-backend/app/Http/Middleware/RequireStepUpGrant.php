<?php

namespace App\Http\Middleware;

use App\Services\FirestoreService;
use Closure;
use Illuminate\Http\Request;

class RequireStepUpGrant
{
    public function handle(Request $request, Closure $next, FirestoreService $firestore, string $action)
    {
        $uid = $request->user()?->firebase_uid;
        $grantId = $request->header('X-Zenith-Step-Up-Id');
        $token = $request->header('X-Zenith-Step-Up-Token');
        $deviceId = $request->header('X-Zenith-Device-Id');
        $secret = config('services.step_up_hmac_secret');
        if (!$uid || !$grantId || !$token || !$deviceId || !$secret || strlen($secret) < 32) {
            return response()->json(['error' => 'Fresh step-up authentication is required.'], 403);
        }
        $grant = $firestore->getDocument("users/{$uid}/step_up_grants", $grantId);
        if (!$grant || ($grant['isUsed'] ?? true) || ($grant['action'] ?? null) !== $action ||
            ($grant['deviceId'] ?? null) !== $deviceId || (int) ($grant['expiresAt'] ?? 0) <= (int) round(microtime(true) * 1000)) {
            return response()->json(['error' => 'Step-up grant is invalid or expired.'], 403);
        }
        $expected = hash_hmac('sha256', "{$uid}|{$action}|{$grantId}|{$grant['expiresAt']}", $secret);
        if (!hash_equals($expected, $token)) return response()->json(['error' => 'Invalid step-up signature.'], 403);
        if (!$firestore->patchDocument("users/{$uid}/step_up_grants", $grantId, ['isUsed' => true, 'usedAt' => gmdate('c')])) {
            return response()->json(['error' => 'Could not consume step-up grant.'], 503);
        }
        return $next($request);
    }
}
