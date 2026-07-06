<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\PlanItineraryRequest;
use App\Http\Requests\RecommendationsRequest;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Symfony\Component\HttpFoundation\Response;

/**
 * [BUG-Q006 / BUG-Q010 / BUG-Q011] AiProxyController
 *
 * Replaces the inline closure AI proxy routes in api.php.
 *
 * Security improvements over the old implementation:
 *  - All requests are validated by typed FormRequest classes BEFORE proxying.
 *  - Only the validated/whitelisted payload is forwarded (prevents injection).
 *  - Python subsystem errors are sanitised — raw upstream messages are never
 *    returned to the client (prevents internal service detail leakage).
 *  - Structured logging at every step for console-friendly debugging.
 *  - Timeout values are configurable via .env (AI_PLAN_TIMEOUT / AI_REC_TIMEOUT).
 */
class AiProxyController extends Controller
{
    /**
     * POST /api/v1/ai/plan-itinerary
     *
     * Forward a validated itinerary generation request to the Python AI backend.
     * Only the explicitly validated fields are forwarded — never raw $request->all().
     */
    public function planItinerary(PlanItineraryRequest $request): \Illuminate\Http\JsonResponse
    {
        $pythonUrl   = config('app.python_backend_url', 'http://localhost:8000');
        $internalKey = config('app.internal_bridge_key', '');
        $timeout     = (int) config('app.ai_plan_timeout', 30);

        // BUG-Q006: Only forward the validated, whitelisted payload.
        $payload = $request->validated();

        Log::info('[AiProxy] plan-itinerary request forwarded to Python backend.', [
            'destination' => $payload['destination'] ?? null,
            'days'        => $payload['days'],
            'style'       => $payload['style'],
        ]);

        try {
            $response = Http::timeout($timeout)
                ->withHeaders(['X-Admin-Internal-Key' => $internalKey])
                ->post("{$pythonUrl}/api/ai/plan-itinerary", $payload);

            // BUG-Q011: Do NOT forward raw upstream error bodies to the client.
            if ($response->failed()) {
                Log::warning('[AiProxy] plan-itinerary upstream failure.', [
                    'status'   => $response->status(),
                    'upstream' => $response->body(), // logged server-side only
                ]);
                return response()->json([
                    'status'  => 'error',
                    'message' => 'AI Itinerary service is currently unavailable. Please try again later.',
                ], Response::HTTP_SERVICE_UNAVAILABLE);
            }

            Log::info('[AiProxy] plan-itinerary upstream success.', ['status' => $response->status()]);

            return response()->json($response->json(), $response->status());

        } catch (\Illuminate\Http\Client\ConnectionException $e) {
            Log::error('[AiProxy] plan-itinerary connection error: ' . $e->getMessage());
            return response()->json([
                'status'  => 'error',
                'message' => 'AI Itinerary service is unreachable. Check backend connectivity.',
            ], Response::HTTP_SERVICE_UNAVAILABLE);
        } catch (\Exception $e) {
            Log::error('[AiProxy] plan-itinerary unexpected error: ' . $e->getMessage());
            return response()->json([
                'status'  => 'error',
                'message' => 'An unexpected error occurred. Please try again.',
            ], Response::HTTP_INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * POST /api/v1/ai/recommendations
     *
     * Forward a validated place-recommendations request to the Python AI backend.
     */
    public function recommendations(RecommendationsRequest $request): \Illuminate\Http\JsonResponse
    {
        $pythonUrl   = config('app.python_backend_url', 'http://localhost:8000');
        $internalKey = config('app.internal_bridge_key', '');
        $timeout     = (int) config('app.ai_rec_timeout', 15);

        // BUG-Q006: Only forward the validated, whitelisted payload.
        $payload = $request->validated();

        Log::info('[AiProxy] recommendations request forwarded to Python backend.', [
            'lat'   => $payload['lat'],
            'lng'   => $payload['lng'],
            'vibe'  => $payload['vibe'] ?? null,
        ]);

        try {
            $response = Http::timeout($timeout)
                ->withHeaders(['X-Admin-Internal-Key' => $internalKey])
                ->post("{$pythonUrl}/api/ai/recommendations", $payload);

            // BUG-Q011: Do NOT forward raw upstream error bodies to the client.
            if ($response->failed()) {
                Log::warning('[AiProxy] recommendations upstream failure.', [
                    'status'   => $response->status(),
                    'upstream' => $response->body(), // logged server-side only
                ]);
                return response()->json([
                    'status'  => 'error',
                    'message' => 'AI Recommendations service is currently unavailable.',
                ], Response::HTTP_SERVICE_UNAVAILABLE);
            }

            Log::info('[AiProxy] recommendations upstream success.', ['status' => $response->status()]);

            return response()->json($response->json(), $response->status());

        } catch (\Illuminate\Http\Client\ConnectionException $e) {
            Log::error('[AiProxy] recommendations connection error: ' . $e->getMessage());
            return response()->json([
                'status'  => 'error',
                'message' => 'AI Recommendations service is unreachable.',
            ], Response::HTTP_SERVICE_UNAVAILABLE);
        } catch (\Exception $e) {
            Log::error('[AiProxy] recommendations unexpected error: ' . $e->getMessage());
            return response()->json([
                'status'  => 'error',
                'message' => 'An unexpected error occurred. Please try again.',
            ], Response::HTTP_INTERNAL_SERVER_ERROR);
        }
    }
}
