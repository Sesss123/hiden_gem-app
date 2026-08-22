<?php

use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| contains the "web" middleware group. Now create something great!
|
*/

use App\Http\Controllers\Admin\AuthController;
use App\Http\Controllers\Admin\PlaceController;
use App\Http\Controllers\Admin\EventController;
use App\Http\Controllers\Admin\GuideController;
use App\Http\Controllers\Admin\UserController;
use App\Http\Controllers\Admin\PartnerController;
use App\Http\Controllers\Admin\IncidentController;
use App\Http\Controllers\Admin\BookingController;
use App\Http\Controllers\Admin\ReviewController;
use App\Http\Controllers\Admin\SubscriptionController;
use App\Http\Controllers\Admin\AuditLogController;
use App\Http\Controllers\JoinController;
use App\Http\Controllers\Api\V1\GuideDocumentUploadController;

Route::get('/', function () {
    return redirect()->route('admin.login');
});

Route::get('/health', function () {
    try {
        \Illuminate\Support\Facades\DB::connection()->getPdo();
        return response()->json(['status' => 'ok', 'checks' => ['database' => 'ok']]);
    } catch (\Exception $e) {
        return response()->json([
            'status' => 'error',
            'checks' => ['database' => 'failed: ' . $e->getMessage()],
        ], 503);
    }
});

// Public family-sharing "join" page — no auth, rate limited to blunt token
// enumeration attempts against the share token (26 chars from a 33-symbol
// alphabet, ~131 bits — the throttle is defense-in-depth, not the primary
// protection). Displayed status is E2E encrypted; see JoinController.
Route::get('/join/{token}', [JoinController::class, 'show'])
    ->middleware('throttle:20,1')
    ->name('join.show');

Route::prefix('admin')->name('admin.')->group(function () {
    Route::get('/login', [AuthController::class, 'showLogin'])->name('login');
    Route::post('/login', [AuthController::class, 'login'])->middleware('throttle:5,1');
    Route::post('/logout', [AuthController::class, 'logout'])->name('logout');

    // Shared: reachable by both the restricted content_manager role and full admins.
    // content_manager can browse/create/edit any place (editing an already-approved
    // place resets it to pending for re-review, enforced in PlaceController::update())
    // — destroy stays full-admin-only below since deletion has no equivalent
    // review/undo safety net.
    Route::middleware(['auth', 'content_manager_or_admin'])->group(function () {
        Route::get('/search', [\App\Http\Controllers\Admin\SearchController::class, 'index'])->name('search');

        Route::get('/my-submissions', [PlaceController::class, 'mySubmissions'])->name('places.my-submissions');
        Route::get('/my-events', [EventController::class, 'mySubmissions'])->name('events.my-submissions');

        // Resolves shortened Google Maps links (maps.app.goo.gl/...) — the
        // coordinates only exist in the URL Google redirects to, not in the
        // short link itself, and a browser can't follow that redirect from
        // client-side JS (cross-origin). Throttled since it's an outbound
        // HTTP call triggered by user input.
        Route::get('/places/resolve-maps-link', [PlaceController::class, 'resolveMapsLink'])
            ->name('places.resolve-maps-link')
            ->middleware('throttle:20,1');

        Route::resource('places', PlaceController::class)->only(['index', 'create', 'edit']);
        Route::resource('events', EventController::class)->only(['index', 'create', 'edit']);

        // Mutating writes throttled (30/min) — content_manager mutates events
        // directly with no approval gate, same abuse risk as full-admin writes.
        Route::middleware('throttle:30,1')->group(function () {
            Route::post('places/import', [PlaceController::class, 'importJson'])->name('places.import');
            Route::resource('places', PlaceController::class)->only(['store', 'update']);
            Route::resource('events', EventController::class)->only(['store', 'update', 'destroy']);

            // Unlike Place images (full_admin-only below — a content_manager's
            // place edits get reset to pending for re-review, so they
            // shouldn't be able to unilaterally finalize a cover photo),
            // content_manager has full unreviewed edit rights over Events
            // (see comment atop this group) and previously had no way to
            // ever delete or re-cover an event photo after uploading it —
            // the controls were hidden and these routes were full_admin-only,
            // an oversight carried over unchanged from the Places form.
            Route::delete('event-images/{id}', [EventController::class, 'deleteImage'])->name('event-images.delete');
            Route::post('event-images/{id}/cover', [EventController::class, 'setCoverImage'])->name('event-images.cover');
        });
    });

    Route::middleware(['auth', 'full_admin'])->group(function () {
        Route::get('/', [\App\Http\Controllers\Admin\DashboardController::class, 'index'])->name('dashboard');
        Route::get('/dashboard', [\App\Http\Controllers\Admin\DashboardController::class, 'index'])->name('dashboard.index');

        // 'show' intentionally excluded on both — neither controller has a
        // show() method or dedicated detail view (edit() serves as the
        // detail/edit page for both, same pattern as Places/Events). Listing
        // 'show' here without a matching method previously registered a
        // route that threw a fatal 500 (not a 404) if ever hit directly.
        Route::resource('partners', PartnerController::class)->only(['index', 'create', 'edit']);
        Route::resource('users', UserController::class)->only(['index', 'create', 'edit']);

        // Guide verification document viewer — see security note on
        // GuideDocumentUploadController::upload()/download(). Session
        // (auth + full_admin) gated, same as the rest of this route group.
        Route::get('/guide-documents/{uid}/{filename}', [GuideDocumentUploadController::class, 'download'])
            ->name('guide-documents.download');

        // Read-only listing/detail views — never throttled, admins hit these constantly.
        Route::get('/guides', [GuideController::class, 'index'])->name('guides.index');
        Route::get('/guides/{id}', [GuideController::class, 'show'])->name('guides.show');
        Route::get('/places-pending', [PlaceController::class, 'pending'])->name('places.pending');
        Route::get('/events-pending', [EventController::class, 'pending'])->name('events.pending');
        Route::get('/incidents', [IncidentController::class, 'index'])->name('incidents.index');
        Route::get('/incidents/{id}', [IncidentController::class, 'show'])->name('incidents.show');
        Route::get('/bookings', [BookingController::class, 'index'])->name('bookings.index');
        Route::get('/bookings/{id}', [BookingController::class, 'show'])->name('bookings.show');
        Route::get('/reviews', [ReviewController::class, 'index'])->name('reviews.index');
        Route::get('/subscriptions', [SubscriptionController::class, 'index'])->name('subscriptions.index');
        Route::get('/audit-log', [AuditLogController::class, 'index'])->name('audit-log.index');

        // Mutating actions (approve/reject/destroy/ban/cancel/hide) throttled
        // to 30/min — friction against a compromised session or scripted abuse,
        // loose enough not to interfere with normal admin clicking.
        Route::middleware('throttle:30,1')->group(function () {
            Route::resource('places', PlaceController::class)->only(['destroy']);
            Route::delete('images/{id}', [PlaceController::class, 'deleteImage'])->name('images.delete');
            Route::post('images/{id}/cover', [PlaceController::class, 'setCoverImage'])->name('images.cover');
            Route::post('/places/{id}/approve', [PlaceController::class, 'approve'])->name('places.approve');
            Route::post('/places/{id}/reject', [PlaceController::class, 'reject'])->name('places.reject');

            Route::post('/events/{id}/approve', [EventController::class, 'approve'])->name('events.approve');
            Route::post('/events/{id}/reject', [EventController::class, 'reject'])->name('events.reject');

            Route::resource('partners', PartnerController::class)->only(['store', 'update', 'destroy']);

            Route::post('/guides/{id}/approve', [GuideController::class, 'approve'])->name('guides.approve');
            Route::post('/guides/{id}/reject', [GuideController::class, 'reject'])->name('guides.reject');
            Route::post('/guides/{id}/ban', [GuideController::class, 'ban'])->name('guides.ban');
            Route::post('/guides/{id}/remove', [GuideController::class, 'remove'])->name('guides.remove');

            Route::resource('users', UserController::class)->only(['store', 'update', 'destroy']);

            Route::post('/incidents/{id}/resolve', [IncidentController::class, 'resolve'])->name('incidents.resolve');
            Route::post('/incidents/{id}/dismiss', [IncidentController::class, 'dismiss'])->name('incidents.dismiss');

            Route::post('/bookings/{id}/cancel', [BookingController::class, 'cancel'])->name('bookings.cancel');
            Route::post('/bookings/{id}/refund', [BookingController::class, 'refund'])->name('bookings.refund');

            Route::post('/reviews/{id}/hide', [ReviewController::class, 'hide'])->name('reviews.hide');
            Route::post('/reviews/{id}/restore', [ReviewController::class, 'restore'])->name('reviews.restore');
        });
    });
});
