<?php

namespace App\Http\Middleware;

use App\Services\FirestoreService;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;

class VerifyZenithSignature
{
    /** Verify the registered ECDSA device key, rotating session token and nonce. */
    public function handle(Request $request, Closure $next, FirestoreService $firestore)
    {
        $timestamp = $request->header('X-Zenith-Timestamp');
        $nonce = $request->header('X-Zenith-Nonce');
        $deviceId = $request->header('X-Zenith-Device-Id');
        $signature = $request->header('X-Zenith-Device-Signature');
        $sessionId = $request->header('X-Zenith-Session-Id');
        $sessionToken = $request->header('X-Zenith-Session-Token');
        if (!$timestamp || !$nonce || !$deviceId || !$sessionId || !$sessionToken) {
            return response()->json(['error' => 'Missing device-bound session headers.'], 401);
        }

        $timestampMs = filter_var($timestamp, FILTER_VALIDATE_INT);
        $nowMs = (int) round(microtime(true) * 1000);
        if ($timestampMs === false || abs($nowMs - $timestampMs) > 5 * 60 * 1000) {
            return response()->json(['error' => 'Request signature expired.'], 401);
        }
        $nonceKey = 'zenith_nonce:' . hash('sha256', $deviceId . '|' . $nonce);
        if (!Cache::add($nonceKey, true, now()->addMinutes(6))) {
            return response()->json(['error' => 'Request replay detected.'], 409);
        }

        $uid = $request->user()?->firebase_uid;
        if (!$uid) return response()->json(['error' => 'Firebase identity is not linked.'], 401);
        $device = $firestore->getDocument("users/{$uid}/devices", $deviceId);
        $session = $firestore->getDocument("users/{$uid}/sessions", $sessionId);
        $posture = $firestore->getDocument("users/{$uid}/security", 'posture');
        if (($posture['isBlocked'] ?? false) === true) {
            return response()->json(['error' => 'Security policy blocked this session.'], 403);
        }
        if (!$device || ($device['isRevoked'] ?? false) || !$session || ($session['isRevoked'] ?? false)) {
            return response()->json(['error' => 'Device or session is not trusted.'], 401);
        }
        $expectedTokenHash = (string) ($session['currentActiveTokenHash'] ?? '');
        if (($session['deviceId'] ?? null) !== $deviceId ||
            !$expectedTokenHash || !hash_equals($expectedTokenHash, hash('sha256', $sessionToken))) {
            return response()->json(['error' => 'Invalid device session.'], 401);
        }
        $createdAt = isset($session['createdAt']) ? strtotime((string) $session['createdAt']) : false;
        if (!$createdAt || time() - $createdAt > 12 * 60 * 60) {
            return response()->json(['error' => 'Session requires fresh authentication.'], 401);
        }

        // PHP cannot reconstruct multipart bytes after parsing. Uploads still
        // require Sanctum plus the validated device/session token above.
        if ($this->isMultipart($request)) return $next($request);
        if (!$signature) return response()->json(['error' => 'Missing device signature.'], 401);

        $bodyHash = hash('sha256', $request->getContent() ?? '');
        $path = ltrim($request->path(), '/');
        $payload = $request->method() . '|' . $path . '|' . $timestamp . '|' . $nonce . '|' . $bodyHash;
        $payloadWithSlash = $request->method() . '|/' . $path . '|' . $timestamp . '|' . $nonce . '|' . $bodyHash;
        $decoded = base64_decode($signature, true);
        $publicKey = $device['publicKeyPem'] ?? null;
        if ($decoded === false || !$publicKey) return response()->json(['error' => 'Invalid device signature encoding.'], 401);
        $valid = openssl_verify($payload, $decoded, $publicKey, OPENSSL_ALGO_SHA256) === 1 ||
            openssl_verify($payloadWithSlash, $decoded, $publicKey, OPENSSL_ALGO_SHA256) === 1;
        if (!$valid) return response()->json(['error' => 'Invalid device signature.'], 401);
        return $next($request);
    }

    private function isMultipart(Request $request): bool
    {
        return str_starts_with((string) $request->header('Content-Type'), 'multipart/form-data');
    }
}
