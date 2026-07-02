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
use App\Http\Controllers\Admin\ReviewController;
use App\Http\Controllers\Admin\AiCommandController;
use App\Http\Controllers\Admin\SchedulerController;

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

        // Review Queue
        Route::get('/reviews', [ReviewController::class, 'index'])->name('reviews.index');
        Route::post('/places/{id}/approve', [ReviewController::class, 'approve'])->name('places.approve');
        Route::post('/places/{id}/reject', [ReviewController::class, 'reject'])->name('places.reject');

        // AI Command Center
        Route::get('/ai-command', [AiCommandController::class, 'index'])->name('ai-command.index');
        Route::post('/ai-command/discover', [AiCommandController::class, 'triggerDiscovery'])->name('ai.discover');
        Route::post('/ai-command/intake', [AiCommandController::class, 'harvestIntake'])->name('ai.intake');

        // Job Scheduler & Backups
        Route::get('/scheduler', [SchedulerController::class, 'index'])->name('scheduler.index');
        Route::post('/scheduler/run/{id}', [SchedulerController::class, 'runNow'])->name('scheduler.run');
        Route::post('/scheduler/backup', [SchedulerController::class, 'runBackup'])->name('scheduler.backup');
    });
});
