<?php

namespace App\Console;

use Illuminate\Console\Scheduling\Schedule;
use Illuminate\Foundation\Console\Kernel as ConsoleKernel;

class Kernel extends ConsoleKernel
{
    /**
     * Define the application's command schedule.
     *
     * @param  Schedule  $schedule
     * @return void
     */
    protected function schedule(Schedule $schedule)
    {
        // Automatically repair sync_version for raw SQL inserts
        $schedule->command('places:repair-sync')
                 ->everyMinute()
                 ->withoutOverlapping();

        // Refreshes the featured-listings / AR-enabled-locations caches and
        // pushes a Reverb broadcast when either actually changed — see
        // BroadcastMarketplaceUpdates for why this exists instead of relying
        // on the lazy Cache::remember() in MarketplaceController.
        $schedule->command('marketplace:broadcast-updates')
                 ->everyFiveMinutes()
                 ->withoutOverlapping();

        // Unfeature listings whose 30-day featured window has passed —
        // see ExpireFeaturedListings for why this exists.
        $schedule->command('marketplace:expire-featured-listings')
                 ->daily()
                 ->withoutOverlapping();

        // Cleans up expired-but-undeleted personal_access_tokens rows now
        // that tokens actually expire (see config/sanctum.php) — otherwise
        // they accumulate forever since Sanctum never deletes them on its
        // own. --hours=24 gives a grace window past expiry before deleting.
        $schedule->command('sanctum:prune-expired --hours=24')
                 ->daily()
                 ->withoutOverlapping();
    }

    /**
     * Register the commands for the application.
     *
     * @return void
     */
    protected function commands()
    {
        $this->load(__DIR__.'/Commands');

        require base_path('routes/console.php');
    }
}
