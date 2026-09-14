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
use App\Http\Controllers\Api\EventSyncController;
use App\Http\Controllers\Api\AiProxyController;
use App\Http\Controllers\Api\RevenueCatWebhookController;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\WishlistController;
use App\Http\Controllers\Api\V1\GuideApplicationController;
use App\Http\Controllers\Api\V1\GuideListingController;
use App\Http\Controllers\Api\V1\PayHereController;
use App\Http\Controllers\Api\V1\GuideDocumentUploadController;
use App\Http\Controllers\Api\V1\ReviewController;
use App\Http\Controllers\Api\V1\BookingController;
use App\Http\Controllers\Api\V1\MarketplaceController;
use App\Http\Controllers\Api\V1\MarketplacePhotoUploadController;
use App\Http\Controllers\Api\V1\SecurityController;
use App\Http\Middleware\VerifyApiKey;
use App\Http\Middleware\VerifyRevenueCatWebhook;

Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
    return $request->user();
});

Route::post('/webhooks/revenuecat', [RevenueCatWebhookController::class, 'handle'])
    ->middleware(VerifyRevenueCatWebhook::class);

Route::post('/v1/payments/notify', [PayHereController::class, 'notify'])->name('payments.notify');
Route::get('/v1/payments/return', [PayHereController::class, 'paymentReturn'])->name('payments.return');
Route::get('/v1/payments/cancel', [PayHereController::class, 'paymentCancel'])->name('payments.cancel');
Route::get('/v1/payments/redirect/{bookingId}', [PayHereController::class, 'redirect'])
    ->name('payments.redirect')
    ->middleware('signed');

// v1 API Endpoints
Route::prefix('v1')->group(function () {
    // Public Auth Routes (Rate limited to prevent brute force attacks)
    Route::middleware('throttle:5,1')->group(function () {
        Route::post('/auth/register', [AuthController::class, 'register']);
        Route::post('/auth/login', [AuthController::class, 'login']);
        Route::post('/auth/firebase-login', [AuthController::class, 'firebaseLogin']);
    });

    // Protected Auth & Wishlist Routes (Require Sanctum Bearer Token)
    Route::middleware(['auth:sanctum', 'zenith'])->group(function () {
        Route::get('/auth/profile', [AuthController::class, 'profile']);
        Route::post('/auth/logout', [AuthController::class, 'logout']);
        Route::delete('/auth/account', [AuthController::class, 'deleteAccount']);

        Route::get('/user/wishlist', [WishlistController::class, 'index']);
        Route::post('/places/{id}/bookmark', [WishlistController::class, 'toggle']);
    });

    Route::prefix('places')->middleware([VerifyApiKey::class, 'throttle:60,1'])->group(function () {
        Route::get('/', [PlaceSyncController::class, 'allPlaces']);
        Route::get('/check-version', [PlaceSyncController::class, 'checkVersion']);
        Route::get('/delta', [PlaceSyncController::class, 'delta']);
        Route::get('/{id}/nearby', [PlaceSyncController::class, 'nearby']);
    });

    Route::prefix('guide-applications')->middleware(['auth:sanctum', VerifyApiKey::class, 'zenith', 'throttle:30,1'])->group(function () {
        Route::post('/', [GuideApplicationController::class, 'submit']);
        Route::get('/status/{userId}', [GuideApplicationController::class, 'myStatus']);
        Route::post('/documents', [GuideDocumentUploadController::class, 'upload']);
    });

    // Admin Guide Applications Routes (Protected by Sanctum Auth, Admin Role, API Key & Rate Limiting)
    Route::prefix('admin/guide-applications')->middleware(['auth:sanctum', 'is_admin', VerifyApiKey::class, 'zenith', 'throttle:60,1'])->group(function () {
        Route::get('/', [GuideApplicationController::class, 'index']);
        Route::post('/{id}/approve', [GuideApplicationController::class, 'approve'])->middleware('step_up:admin_moderation');
        Route::post('/{id}/reject', [GuideApplicationController::class, 'reject'])->middleware('step_up:admin_moderation');
    });

    // Admin Guide Listings Moderation Routes (Protected by Sanctum Auth, Admin Role, API Key & Rate Limiting)
    Route::prefix('admin/guide-listings')->middleware(['auth:sanctum', 'is_admin', VerifyApiKey::class, 'zenith', 'throttle:60,1'])->group(function () {
        Route::get('/', [GuideListingController::class, 'index']);
        Route::post('/{listingId}/approve', [GuideListingController::class, 'approve'])->middleware('step_up:admin_moderation');
        Route::post('/{listingId}/reject', [GuideListingController::class, 'reject'])->middleware('step_up:admin_moderation');
        Route::post('/{listingId}/featured', [GuideListingController::class, 'setFeatured'])->middleware('step_up:admin_moderation');
    });

    // Review Routes (Protected by Sanctum Auth, API Key & Rate Limiting)
    Route::prefix('reviews')->middleware(['auth:sanctum', VerifyApiKey::class, 'zenith', 'throttle:30,1'])->group(function () {
        Route::post('/{reviewId}/recalculate', [ReviewController::class, 'recalculate']);
        Route::get('/guide/{guideId}', [ReviewController::class, 'guideReviews']);
    });

    // Marketplace Listing Routes (Protected by Sanctum Auth, API Key & Rate Limiting)
    Route::prefix('listings')->middleware(['auth:sanctum', VerifyApiKey::class, 'throttle:60,1'])->group(function () {
        Route::get('/featured', [MarketplaceController::class, 'featured']);
        Route::get('/search', [MarketplaceController::class, 'search']);
    });

    // Marketplace Photo Uploads (cover/vehicle photos — Protected by Sanctum Auth, API Key & Rate Limiting)
    Route::prefix('marketplace')->middleware(['auth:sanctum', VerifyApiKey::class, 'zenith', 'throttle:30,1'])->group(function () {
        Route::post('/photos', [MarketplacePhotoUploadController::class, 'upload']);
    });

    // AR Video Library Routes (Protected by Sanctum Auth, API Key & Rate Limiting)
    Route::prefix('ar')->middleware(['auth:sanctum', VerifyApiKey::class, 'throttle:60,1'])->group(function () {
        Route::get('/enabled-locations', [MarketplaceController::class, 'arEnabledLocations']);
    });

    // Booking Routes (Protected by Sanctum Auth, API Key & Rate Limiting)
    Route::prefix('bookings')->middleware(['auth:sanctum', VerifyApiKey::class, 'zenith', 'throttle:30,1'])->group(function () {
        Route::get('/quota-check', [BookingController::class, 'quotaCheck']);
        Route::get('/priority-check', [BookingController::class, 'priorityCheck']);
        Route::post('/{bookingId}/notify-guide', [BookingController::class, 'notifyGuide']);
        Route::post('/{bookingId}/quote', [BookingController::class, 'sendQuote']);
        Route::post('/{bookingId}/accept-with-session', [BookingController::class, 'acceptWithSession']);
    });

    Route::prefix('payments')->middleware(['auth:sanctum', VerifyApiKey::class, 'zenith', 'throttle:30,1'])->group(function () {
        Route::post('/checkout', [PayHereController::class, 'checkout']);
    });

    // Security Routes (Protected by Sanctum Auth, API Key & Rate Limiting)
    Route::prefix('security')->middleware(['auth:sanctum', VerifyApiKey::class, 'zenith', 'throttle:30,1'])->group(function () {
        Route::get('/device-account-count', [SecurityController::class, 'deviceAccountCount']);
    });
    Route::prefix('security')->middleware(['auth:sanctum', VerifyApiKey::class, 'throttle:30,1'])->group(function () {
        Route::post('/device-key', [SecurityController::class, 'registerDeviceKey']);
        Route::post('/session/rotate', [SecurityController::class, 'rotateSession']);
    });
    Route::post('/security/step-up', [SecurityController::class, 'issueStepUpGrant'])
        ->middleware(['auth:sanctum', VerifyApiKey::class, 'zenith', 'throttle:10,1']);
    Route::prefix('security')->middleware(['auth:sanctum', VerifyApiKey::class, 'zenith', 'throttle:30,1'])->group(function () {
        Route::post('/posture', [SecurityController::class, 'evaluatePosture']);
        Route::post('/session/revoke', [SecurityController::class, 'revokeSession']);
        Route::post('/sessions/revoke-all', [SecurityController::class, 'revokeAllSessions']);
    });


    Route::middleware(['auth:sanctum', VerifyApiKey::class, 'zenith', 'throttle:10,1'])->group(function () {
        Route::post('/ai/plan-itinerary', [AiProxyController::class, 'planItinerary']);
        Route::post('/ai/recommendations', [AiProxyController::class, 'recommendations']);
        Route::post('/ai/chat', [AiProxyController::class, 'chat']);
        Route::post('/ai/food/scan', [AiProxyController::class, 'foodScan']);
        Route::get('/ai/status', [AiProxyController::class, 'status']);
    });

    Route::prefix('discovery')->middleware([VerifyApiKey::class, 'throttle:60,1'])->group(function () {
        Route::get('/events', [EventSyncController::class, 'events']);
    });

    // Remote App Configuration & Ads Master Switch (Public, high performance)
    Route::get('/config/ads', function () {
        $adsEnabled = false;
        try {
            $adsEnabled = \App\Models\AppSetting::isAdsEnabled();
        } catch (\Throwable $e) {
            // Fail closed if settings storage is unavailable.
        }

        return response()->json([
            'success' => true,
            'ads_enabled' => $adsEnabled,
            'network' => 'admob',
            'timestamp' => now()->timestamp,
        ])->header('Cache-Control', 'no-store, max-age=0');
    })->middleware('throttle:120,1');

    Route::get('/config/prices', function () {
        $version = (int) \Illuminate\Support\Facades\Cache::get('public_price_catalog_version', 1);
        $items = \Illuminate\Support\Facades\Cache::remember('public_price_catalog_v1', 300, function () {
            return \App\Models\PriceCatalogItem::currentlyAvailable()->orderBy('key')->get()
                ->mapWithKeys(fn (\App\Models\PriceCatalogItem $item) => [$item->key => $item->toPublicArray()])->all();
        });
        return response()->json(['success' => true, 'version' => $version, 'prices' => $items, 'updated_at' => now()->toIso8601String()])
            ->header('Cache-Control', 'public, max-age=60, stale-if-error=86400')
            ->header('ETag', '"prices-' . $version . '"');
    })->middleware('throttle:120,1');
});
