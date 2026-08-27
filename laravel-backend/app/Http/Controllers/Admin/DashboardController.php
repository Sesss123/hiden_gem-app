<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Place;
use App\Models\User;
use App\Models\Wishlist;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class DashboardController extends Controller
{
    public function index()
    {
        $totalPlaces = Place::count();
        $arPlaces = Place::where('ar_supported', true)->count();

        $totalUsers = User::count();
        $hasSubTier = Schema::hasColumn('users', 'subscription_tier');
        $proUsers = $hasSubTier ? User::where('subscription_tier', 'PRO')->count() : 0;
        $vipUsers = $hasSubTier ? User::where('subscription_tier', 'VIP')->count() : 0;

        $totalWishlists = Schema::hasTable('wishlists') ? Wishlist::count() : 0;

        // BUG-009 Fix: Document that DB::raw is safe here because inputs are hardcoded strings without user variables
        $byDistrict = Place::select('district', DB::raw('count(*) as total'))
            ->groupBy('district')
            ->orderByDesc('total')
            ->take(25)
            ->get();

        $byCategory = Place::select('category', DB::raw('count(*) as total'))
            ->groupBy('category')
            ->orderByDesc('total')
            ->take(12)
            ->get();

        $recentPlaces = Place::with('images')
            ->orderByDesc('updated_at')
            ->take(5)
            ->get();

        $duplicates = Place::select('name', 'district', DB::raw('count(*) as cnt'), DB::raw('GROUP_CONCAT(id SEPARATOR ", ") as duplicate_ids'))
            ->where('is_deleted', false)
            ->groupBy('name', 'district')
            ->having('cnt', '>', 1)
            ->take(50)
            ->get();

        // The badge shows the real total group count, not just how many
        // rows were rendered — a wrapped COUNT over the grouped subquery
        // so this stays a single indexed aggregate rather than re-running
        // the unbounded group/having scan a second time.
        $duplicatesCount = DB::table(DB::raw('(select 1 from places where is_deleted = 0 group by name, district having count(*) > 1) as dup_groups'))->count();

        return view('admin.dashboard', compact(
            'totalPlaces', 'arPlaces',
            'totalUsers', 'proUsers', 'vipUsers',
            'totalWishlists', 'byDistrict', 'byCategory', 'recentPlaces', 'duplicates', 'duplicatesCount'
        ));
    }
}
