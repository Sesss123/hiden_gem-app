<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| is assigned the "api" middleware group. Enjoy building your API!
|
*/

use App\Http\Controllers\Api\PlaceSyncController;
use App\Http\Controllers\Api\AiProxyController;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\WishlistController;
use App\Http\Controllers\Api\V1\GuideApplicationController;
use App\Http\Middleware\VerifyApiKey;

Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
    return $request->user();
});

// v1 API Endpoints
Route::prefix('v1')->group(function () {
    // Public Auth Routes (Rate limited to prevent brute force attacks)
    Route::middleware('throttle:5,1')->group(function () {
        Route::post('/auth/register', [AuthController::class, 'register']);
        Route::post('/auth/login', [AuthController::class, 'login']);
        Route::post('/auth/firebase-login', [AuthController::class, 'firebaseLogin']);
    });

    // Protected Auth & Wishlist Routes (Require Sanctum Bearer Token)
    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/auth/profile', [AuthController::class, 'profile']);
        Route::post('/auth/logout', [AuthController::class, 'logout']);

        Route::get('/user/wishlist', [WishlistController::class, 'index']);
        Route::post('/places/{id}/bookmark', [WishlistController::class, 'toggle']);
    });

    // Place Sync API Routes (Protected by Sanctum Auth, API Key & Rate Limiting)
    Route::prefix('places')->middleware(['auth:sanctum', VerifyApiKey::class, 'throttle:60,1'])->group(function () {
        Route::get('/', [PlaceSyncController::class, 'allPlaces']);
        Route::get('/check-version', [PlaceSyncController::class, 'checkVersion']);
        Route::get('/delta', [PlaceSyncController::class, 'delta']);
    });

    // Guide Applications API Routes (Protected by Sanctum Auth, API Key & Rate Limiting)
    Route::prefix('guide-applications')->middleware(['auth:sanctum', VerifyApiKey::class, 'throttle:30,1'])->group(function () {
        Route::post('/', [GuideApplicationController::class, 'submit']);
        Route::get('/status/{userId}', [GuideApplicationController::class, 'myStatus']);
    });

    // Admin Guide Applications Routes (Protected by Sanctum Auth, Admin Role, API Key & Rate Limiting)
    Route::prefix('admin/guide-applications')->middleware(['auth:sanctum', 'is_admin', VerifyApiKey::class, 'throttle:60,1'])->group(function () {
        Route::get('/', [GuideApplicationController::class, 'index']);
        Route::post('/{id}/approve', [GuideApplicationController::class, 'approve']);
        Route::post('/{id}/reject', [GuideApplicationController::class, 'reject']);
    });

    // AI Subsystem Proxy Routes (Protected by Sanctum Auth, API Key, and Throttling)
    // BUG-Q006 / BUG-Q010 / BUG-Q011: Replaced inline closures with AiProxyController.
    // All requests are now validated via FormRequest before being forwarded to Python.
    // Python upstream errors are sanitised — raw error bodies are never returned to clients.
    Route::middleware(['auth:sanctum', VerifyApiKey::class, 'throttle:30,1'])->group(function () {
        Route::post('/ai/plan-itinerary', [AiProxyController::class, 'planItinerary']);
        Route::post('/ai/recommendations', [AiProxyController::class, 'recommendations']);
    });
});
