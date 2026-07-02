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

Route::get('/', function () {
    return redirect()->route('admin.login');
});

Route::prefix('admin')->name('admin.')->group(function () {
    Route::get('/login', [AuthController::class, 'showLogin'])->name('login');
    Route::post('/login', [AuthController::class, 'login']);
    Route::post('/logout', [AuthController::class, 'logout'])->name('logout');

    Route::middleware('auth')->group(function () {
        Route::get('/', [\App\Http\Controllers\Admin\DashboardController::class, 'index'])->name('dashboard');
        Route::get('/dashboard', [\App\Http\Controllers\Admin\DashboardController::class, 'index'])->name('dashboard.index');
        Route::resource('places', PlaceController::class);
        Route::delete('images/{id}', [PlaceController::class, 'deleteImage'])->name('images.delete');
        Route::post('images/{id}/cover', [PlaceController::class, 'setCoverImage'])->name('images.cover');


        // Events CRUD
        Route::resource('events', EventController::class);

        // Guide Moderation
        Route::get('/guides', [GuideController::class, 'index'])->name('guides.index');
        Route::get('/guides/{id}', [GuideController::class, 'show'])->name('guides.show');
        Route::post('/guides/{id}/approve', [GuideController::class, 'approve'])->name('guides.approve');
        Route::post('/guides/{id}/reject', [GuideController::class, 'reject'])->name('guides.reject');
        Route::post('/guides/{id}/ban', [GuideController::class, 'ban'])->name('guides.ban');
        Route::post('/guides/{id}/remove', [GuideController::class, 'remove'])->name('guides.remove');

        // Users CRUD
        Route::resource('users', UserController::class);
    });
});
