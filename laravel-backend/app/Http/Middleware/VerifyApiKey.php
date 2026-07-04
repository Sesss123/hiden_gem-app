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
        // BUG-L01 Fix: Use config() instead of env() so config:cache doesn't break API authentication in production
        $expectedKey = config('app.api_key');
        
        if (empty($expectedKey)) {
            return response()->json(['error' => 'Server configuration error: Missing API key configuration.'], 500);
        }
        $providedKey = $request->header('X-API-KEY');

        if (!$providedKey || !hash_equals($expectedKey, $providedKey)) {
            return response()->json([
                'error' => 'Unauthorized. Valid X-API-KEY header required.'
            ], 401);
        }

        return $next($request);
    }
}
