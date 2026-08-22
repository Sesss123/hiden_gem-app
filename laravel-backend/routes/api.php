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

// RevenueCat Webhook (server-to-server; no Sanctum token — authenticated via
// its own shared-secret Authorization header instead. See VerifyRevenueCatWebhook.)
Route::post('/webhooks/revenuecat', [RevenueCatWebhookController::class, 'handle'])
    ->middleware(VerifyRevenueCatWebhook::class);

// PayHere payment callbacks (server-to-server + browser redirects; NO Sanctum
// token — the notify callback is authenticated by PayHere's own md5 signature,
// verified inside the controller). These must be public so PayHere's servers
// and the user's browser can reach them.
Route::post('/v1/payments/notify', [PayHereController::class, 'notify'])->name('payments.notify');
Route::get('/v1/payments/return', [PayHereController::class, 'paymentReturn'])->name('payments.return');
Route::get('/v1/payments/cancel', [PayHereController::class, 'paymentCancel'])->name('payments.cancel');
// Signed browser redirect that auto-submits the PayHere form. Auth is the
// signed URL itself (issued by /payments/checkout after ownership check), so
// no Sanctum token is needed for this plain browser navigation.
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
    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/auth/profile', [AuthController::class, 'profile']);
        Route::post('/auth/logout', [AuthController::class, 'logout']);
        Route::delete('/auth/account', [AuthController::class, 'deleteAccount']);

        Route::get('/user/wishlist', [WishlistController::class, 'index']);
        Route::post('/places/{id}/bookmark', [WishlistController::class, 'toggle']);
    });

    // Place Sync API Routes (API Key & Rate Limiting — intentionally NOT
    // behind auth:sanctum: the app calls this during first-launch boot sync,
    // before any account/token exists, and every response here is identical
    // for any caller — PlaceSyncController's methods never read $request->user()
    // or any per-user state, only public approved-place data. Requiring
    // Sanctum here 401s every fresh install's initial sync, which
    // delta_sync_service.dart silently treats as "no update" — the app is
    // left with a permanently empty local catalog and no visible error.)
    Route::prefix('places')->middleware([VerifyApiKey::class, 'throttle:60,1'])->group(function () {
        Route::get('/', [PlaceSyncController::class, 'allPlaces']);
        Route::get('/check-version', [PlaceSyncController::class, 'checkVersion']);
        Route::get('/delta', [PlaceSyncController::class, 'delta']);
        Route::get('/{id}/nearby', [PlaceSyncController::class, 'nearby']);
    });

    // Guide Applications API Routes (Protected by Sanctum Auth, API Key & Rate Limiting)
    // 'zenith' verifies the X-Zenith-* request signature on non-multipart
    // requests (the middleware self-skips the multipart /documents upload).
    Route::prefix('guide-applications')->middleware(['auth:sanctum', VerifyApiKey::class, 'zenith', 'throttle:30,1'])->group(function () {
        Route::post('/', [GuideApplicationController::class, 'submit']);
        Route::get('/status/{userId}', [GuideApplicationController::class, 'myStatus']);
        Route::post('/documents', [GuideDocumentUploadController::class, 'upload']);
    });

    // Admin Guide Applications Routes (Protected by Sanctum Auth, Admin Role, API Key & Rate Limiting)
    Route::prefix('admin/guide-applications')->middleware(['auth:sanctum', 'is_admin', VerifyApiKey::class, 'zenith', 'throttle:60,1'])->group(function () {
        Route::get('/', [GuideApplicationController::class, 'index']);
        Route::post('/{id}/approve', [GuideApplicationController::class, 'approve']);
        Route::post('/{id}/reject', [GuideApplicationController::class, 'reject']);
    });

    // Admin Guide Listings Moderation Routes (Protected by Sanctum Auth, Admin Role, API Key & Rate Limiting)
    Route::prefix('admin/guide-listings')->middleware(['auth:sanctum', 'is_admin', VerifyApiKey::class, 'zenith', 'throttle:60,1'])->group(function () {
        Route::get('/', [GuideListingController::class, 'index']);
        Route::post('/{listingId}/approve', [GuideListingController::class, 'approve']);
        Route::post('/{listingId}/reject', [GuideListingController::class, 'reject']);
        Route::post('/{listingId}/featured', [GuideListingController::class, 'setFeatured']);
    });

    // Review Routes (Protected by Sanctum Auth, API Key & Rate Limiting)
    Route::prefix('reviews')->middleware(['auth:sanctum', VerifyApiKey::class, 'zenith', 'throttle:30,1'])->group(function () {
        Route::post('/{reviewId}/recalculate', [ReviewController::class, 'recalculate']);
        Route::get('/guide/{guideId}', [ReviewController::class, 'guideReviews']);
    });

    // Marketplace Listing Routes (Protected by Sanctum Auth, API Key & Rate Limiting)
    Route::prefix('listings')->middleware(['auth:sanctum', VerifyApiKey::class, 'throttle:60,1'])->group(function () {
        Route::get('/featured', [MarketplaceController::class, 'featured']);
    });

    // Marketplace Photo Uploads (cover/vehicle photos — Protected by Sanctum Auth, API Key & Rate Limiting)
    Route::prefix('marketplace')->middleware(['auth:sanctum', VerifyApiKey::class, 'throttle:30,1'])->group(function () {
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
    });

    // Payment checkout (tourist-initiated; returns signed PayHere params).
    // The notify/return/cancel callbacks are public (registered above) since
    // PayHere's servers / the user's browser hit them without a Sanctum token.
    Route::prefix('payments')->middleware(['auth:sanctum', VerifyApiKey::class, 'zenith', 'throttle:30,1'])->group(function () {
        Route::post('/checkout', [PayHereController::class, 'checkout']);
    });

    // Security Routes (Protected by Sanctum Auth, API Key & Rate Limiting)
    Route::prefix('security')->middleware(['auth:sanctum', VerifyApiKey::class, 'throttle:30,1'])->group(function () {
        Route::get('/device-account-count', [SecurityController::class, 'deviceAccountCount']);
    });

    // AI Subsystem Proxy Routes (Protected by Sanctum Auth, API Key, and Throttling)
    // BUG-Q006 / BUG-Q010 / BUG-Q011: Replaced inline closures with AiProxyController.
    // All requests are now validated via FormRequest before being forwarded to Python.
    // Python upstream errors are sanitised — raw error bodies are never returned to clients.
    Route::middleware(['auth:sanctum', VerifyApiKey::class, 'zenith', 'throttle:30,1'])->group(function () {
        Route::post('/ai/plan-itinerary', [AiProxyController::class, 'planItinerary']);
        Route::post('/ai/recommendations', [AiProxyController::class, 'recommendations']);
    });

    // Discovery API — public content feeds consumed by the app's discovery/
    // content screens. Same reasoning as the Place Sync group above: called
    // during app boot before any account/token exists, and the response is
    // identical for any caller, so it's API-key gated rather than
    // auth:sanctum-gated. AppConfig.baseUrl (Flutter) is laravelUrl, which
    // already ends in "/api/v1" — DynamicContentService.fetchEvents() calls
    // "{baseUrl}/discovery/events", so this must live under the /v1 prefix
    // (unlike PlaceSyncController's /v1/places group, which is also under
    // /v1 — every existing sync-style endpoint here is).
    Route::prefix('discovery')->middleware([VerifyApiKey::class, 'throttle:60,1'])->group(function () {
        Route::get('/events', [EventSyncController::class, 'events']);
    });
});
