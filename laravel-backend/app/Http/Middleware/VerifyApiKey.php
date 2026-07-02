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
        $expectedKey = env('API_KEY', config('app.api_key'));
        
        if (app()->environment('production') && ($expectedKey === null || $expectedKey === 'hg_live_secret_key_2026')) {
            return response()->json(['error' => 'Server configuration error: Insecure API key.'], 500);
        }

        $expectedKey = $expectedKey ?? 'hg_live_secret_key_2026';
        $providedKey = $request->header('X-API-KEY');

        if (!$providedKey || !hash_equals($expectedKey, $providedKey)) {
            return response()->json([
                'error' => 'Unauthorized. Valid X-API-KEY header required.'
            ], 401);
        }

        return $next($request);
    }
}
