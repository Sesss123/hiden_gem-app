<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class VerifyApiKey
{
    /**
     * Handle an incoming request.
     * Validates simple X-API-KEY header to secure endpoints without Firebase.
     */
    public function handle(Request $request, Closure $next)
    {
        $expectedKey = config('app.api_key', 'hg_live_secret_key_2026');
        $providedKey = $request->header('X-API-KEY');

        if (!$providedKey || !hash_equals($expectedKey, $providedKey)) {
            return response()->json([
                'error' => 'Unauthorized. Valid X-API-KEY header required.'
            ], 401);
        }

        return $next($request);
    }
}
