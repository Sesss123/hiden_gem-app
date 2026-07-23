<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class VerifyZenithSignature
{
    /**
     * Verifies the X-Zenith-Timestamp / X-Zenith-Nonce / X-Zenith-Signature
     * headers SecureHttpClient (Flutter) attaches to every request.
     *
     * SECURITY CONTEXT: this was previously generated client-side and never
     * checked anywhere server-side — HARDENING.md documented it as active
     * MITM-tampering/replay-attack protection, which was false. The shared
     * secret is embedded in the app binary (a --dart-define constant, not a
     * true server secret), so this does NOT stop an attacker who has
     * decompiled the app and extracted it. What it DOES stop: a passive
     * network observer (unable to read HTTPS payloads directly, e.g. on a
     * captive/compromised Wi-Fi doing connection-level interception, or a
     * proxy log) from replaying a captured request verbatim after the
     * timestamp window closes, and detects payload tampering in flight for
     * any request that doesn't also carry a valid Sanctum bearer token.
     *
     * Only applied where explicitly routed — verifies JSON/form request
     * bodies. Multipart (file upload) requests are NOT verified here (see
     * skipVerification below) since PHP consumes multipart bodies via
     * superglobals rather than a re-readable raw stream, and reconstructing
     * SecureHttpClient's exact multipart signing input server-side would be
     * fragile; those routes keep relying on auth:sanctum + VerifyApiKey.
     */
    public function handle(Request $request, Closure $next)
    {
        $secret = config('services.zenith_hmac_secret');
        if (empty($secret)) {
            if (app()->environment('production')) {
                // SECURITY: fail CLOSED in production — a blank HMAC_SECRET
                // must never silently degrade this into a no-op
                // verification layer. Any other environment (local,
                // testing, etc.) still fails open below so a developer's
                // default .env (HMAC_SECRET unset) keeps working.
                \Illuminate\Support\Facades\Log::critical(
                    'VerifyZenithSignature: HMAC_SECRET is unset in production — rejecting protected request.',
                    ['path' => $request->path()]
                );
                return response()->json([
                    'error' => 'Server misconfiguration: request verification unavailable.',
                ], 500);
            }

            // Not configured in a non-production environment — fail open so
            // local/testing setups without HMAC_SECRET configured keep working.
            return $next($request);
        }

        if ($this->skipVerification($request)) {
            return $next($request);
        }

        $timestamp = $request->header('X-Zenith-Timestamp');
        $nonce = $request->header('X-Zenith-Nonce');
        $signature = $request->header('X-Zenith-Signature');

        if (!$timestamp || !$nonce || !$signature) {
            return response()->json(['error' => 'Missing request signature headers.'], 401);
        }

        $timestampMs = (int) $timestamp;
        $nowMs = (int) round(microtime(true) * 1000);
        $maxSkewMs = 5 * 60 * 1000; // 5 minutes — generous for clock drift + slow networks
        if (abs($nowMs - $timestampMs) > $maxSkewMs) {
            return response()->json(['error' => 'Request signature expired.'], 401);
        }

        $body = $request->getContent() ?? '';
        $bodyHash = hash('sha256', $body);
        $payload = $request->method() . '|' . $request->path() . '|' . $timestamp . '|' . $nonce . '|' . $bodyHash;
        // Laravel's $request->path() omits the leading slash; the Flutter
        // client signs Uri.path, which includes it. Try both to avoid a
        // false-negative purely from that formatting difference.
        $payloadWithSlash = $request->method() . '|/' . ltrim($request->path(), '/') . '|' . $timestamp . '|' . $nonce . '|' . $bodyHash;

        $expected = hash_hmac('sha256', $payload, $secret);
        $expectedWithSlash = hash_hmac('sha256', $payloadWithSlash, $secret);

        if (!hash_equals($expected, $signature) && !hash_equals($expectedWithSlash, $signature)) {
            return response()->json(['error' => 'Invalid request signature.'], 401);
        }

        return $next($request);
    }

    private function skipVerification(Request $request): bool
    {
        return str_starts_with((string) $request->header('Content-Type'), 'multipart/form-data');
    }
}
