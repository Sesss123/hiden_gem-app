<?php

namespace App\Providers;

use App\Models\Place;
use App\Services\FirestoreService;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\View;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     *
     * @return void
     */
    public function register()
    {
        //
    }

    /**
     * Bootstrap any application services.
     *
     * @return void
     */
    public function boot()
    {
        // Sidebar "open incidents" badge — shown on every admin page (see
        // admin.layout), but a live Firestore query per page load would add
        // real latency to pages that have nothing to do with incidents (e.g.
        // Places, Events). Cached for 60s and fails silently to 0 rather than
        // ever breaking page rendering over a Firestore hiccup.
        View::composer('admin.layout', function ($view) {
            $count = Cache::remember('admin_open_incident_count', 60, function () {
                try {
                    return count((new FirestoreService())->queryDocuments('incident_reports', 'status', 'EQUAL', 'open'));
                } catch (\Exception $e) {
                    Log::warning('Sidebar open-incident count failed: ' . $e->getMessage());
                    return 0;
                }
            });
            $view->with('openIncidentCount', $count);

            $pendingPlaceCount = Cache::remember('admin_pending_place_count', 60, function () {
                return Place::where('status', Place::STATUS_PENDING)->whereNotNull('created_by')->count();
            });
            $view->with('pendingPlaceCount', $pendingPlaceCount);
        });
    }
}
