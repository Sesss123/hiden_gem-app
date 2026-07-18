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
use App\Http\Controllers\JoinController;
use App\Http\Controllers\Api\V1\GuideDocumentUploadController;

Route::get('/', function () {
    return redirect()->route('admin.login');
});

// Public family-sharing "join" page — no auth, rate limited to blunt token
// enumeration attempts against the 8-char share token.
Route::get('/join/{token}', [JoinController::class, 'show'])
    ->middleware('throttle:20,1')
    ->name('join.show');

Route::prefix('admin')->name('admin.')->group(function () {
    Route::get('/login', [AuthController::class, 'showLogin'])->name('login');
    Route::post('/login', [AuthController::class, 'login'])->middleware('throttle:5,1');
    Route::post('/logout', [AuthController::class, 'logout'])->name('logout');

    Route::middleware(['auth', 'is_admin'])->group(function () {
        Route::get('/', [\App\Http\Controllers\Admin\DashboardController::class, 'index'])->name('dashboard');
        Route::get('/dashboard', [\App\Http\Controllers\Admin\DashboardController::class, 'index'])->name('dashboard.index');
        Route::resource('places', PlaceController::class);
        Route::delete('images/{id}', [PlaceController::class, 'deleteImage'])->name('images.delete');
        Route::post('images/{id}/cover', [PlaceController::class, 'setCoverImage'])->name('images.cover');


        // Events CRUD
        Route::resource('events', EventController::class);

        // Curator Partners CRUD (Firestore-backed, no MySQL table)
        Route::resource('partners', PartnerController::class);

        // Guide Moderation
        Route::get('/guides', [GuideController::class, 'index'])->name('guides.index');
        Route::get('/guides/{id}', [GuideController::class, 'show'])->name('guides.show');
        Route::post('/guides/{id}/approve', [GuideController::class, 'approve'])->name('guides.approve');
        Route::post('/guides/{id}/reject', [GuideController::class, 'reject'])->name('guides.reject');
        Route::post('/guides/{id}/ban', [GuideController::class, 'ban'])->name('guides.ban');
        Route::post('/guides/{id}/remove', [GuideController::class, 'remove'])->name('guides.remove');

        // Guide verification document viewer — see security note on
        // GuideDocumentUploadController::upload()/download(). Session
        // (auth + is_admin) gated, same as the rest of this route group.
        Route::get('/guide-documents/{uid}/{filename}', [GuideDocumentUploadController::class, 'download'])
            ->name('guide-documents.download');

        // Users CRUD
        Route::resource('users', UserController::class);

        // Incident Reports (SOS alerts + manual reports) — Firestore-backed
        Route::get('/incidents', [IncidentController::class, 'index'])->name('incidents.index');
        Route::get('/incidents/{id}', [IncidentController::class, 'show'])->name('incidents.show');
        Route::post('/incidents/{id}/resolve', [IncidentController::class, 'resolve'])->name('incidents.resolve');
        Route::post('/incidents/{id}/dismiss', [IncidentController::class, 'dismiss'])->name('incidents.dismiss');

        // Bookings / Tour Sessions — Firestore-backed
        Route::get('/bookings', [BookingController::class, 'index'])->name('bookings.index');
        Route::get('/bookings/{id}', [BookingController::class, 'show'])->name('bookings.show');
        Route::post('/bookings/{id}/cancel', [BookingController::class, 'cancel'])->name('bookings.cancel');

        // Review Moderation — Firestore-backed
        Route::get('/reviews', [ReviewController::class, 'index'])->name('reviews.index');
        Route::post('/reviews/{id}/hide', [ReviewController::class, 'hide'])->name('reviews.hide');
        Route::post('/reviews/{id}/restore', [ReviewController::class, 'restore'])->name('reviews.restore');

        // Premium/Subscription Overview — Firestore-backed, read-only
        Route::get('/subscriptions', [SubscriptionController::class, 'index'])->name('subscriptions.index');
    });
});
