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
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\WishlistController;
use App\Http\Middleware\VerifyApiKey;

Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
    return $request->user();
});

// v1 API Endpoints
Route::prefix('v1')->group(function () {
    // Public Auth Routes
    Route::post('/auth/register', [AuthController::class, 'register']);
    Route::post('/auth/login', [AuthController::class, 'login']);

    // Protected Auth & Wishlist Routes (Require Sanctum Bearer Token)
    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/auth/profile', [AuthController::class, 'profile']);
        Route::post('/auth/logout', [AuthController::class, 'logout']);

        Route::get('/user/wishlist', [WishlistController::class, 'index']);
        Route::post('/places/{id}/bookmark', [WishlistController::class, 'toggle']);
    });

    // Place Sync API Routes (Protected by API Key & Rate Limiting)
    Route::prefix('places')->middleware([VerifyApiKey::class, 'throttle:60,1'])->group(function () {
        Route::get('/check-version', [PlaceSyncController::class, 'checkVersion']);
        Route::get('/delta', [PlaceSyncController::class, 'delta']);
    });
});

