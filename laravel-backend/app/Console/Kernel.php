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
        $schedule->command('places:repair-sync')
                 ->everyMinute()
                 ->withoutOverlapping();

        $schedule->command('marketplace:broadcast-updates')
                 ->everyFiveMinutes()
                 ->withoutOverlapping();

        $schedule->command('marketplace:expire-featured-listings')
                 ->daily()
                 ->withoutOverlapping();

        $schedule->command('sanctum:prune-expired --hours=24')
                 ->daily()
                 ->withoutOverlapping();

        $schedule->command('system:health-check')
                 ->everyFiveMinutes()
                 ->withoutOverlapping();

        $schedule->command('db:backup')
                 ->dailyAt('03:00')
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
