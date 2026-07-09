<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class VerifyRevenueCatWebhook
{
    /**
     * Handle an incoming request.
     * Validates the "Authorization: Bearer <secret>" header RevenueCat sends,
     * against the shared secret configured in the RevenueCat dashboard
     * (Project Settings > Webhooks).
     */
    public function handle(Request $request, Closure $next)
    {
        $expectedSecret = config('services.revenuecat.webhook_secret');

        if (empty($expectedSecret)) {
            return response()->json(['error' => 'Server configuration error: Missing RevenueCat webhook secret.'], 500);
        }

        $authHeader = $request->header('Authorization', '');
        $providedSecret = str_starts_with($authHeader, 'Bearer ')
            ? substr($authHeader, 7)
            : $authHeader;

        if (!$providedSecret || !hash_equals($expectedSecret, $providedSecret)) {
            return response()->json(['error' => 'Unauthorized. Valid RevenueCat webhook secret required.'], 401);
        }

        return $next($request);
    }
}
