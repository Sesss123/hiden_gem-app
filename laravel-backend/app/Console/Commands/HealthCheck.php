<?php

namespace App\Console\Commands;

use App\Services\DiscordAlertService;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;

class HealthCheck extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'system:health-check';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Polls GET /health and alerts via Discord only on a state change (down or recovered), not on every tick.';

    private const CACHE_KEY = 'health_check_last_status';

    public function handle(DiscordAlertService $discord): int
    {
        $url = rtrim(config('app.url'), '/') . '/health';
        $wasHealthy = Cache::get(self::CACHE_KEY, true);

        $isHealthy = false;
        $detail = '';
        try {
            $response = Http::timeout(10)->get($url);
            $isHealthy = $response->successful();
            $detail = $isHealthy ? '' : ($response->json('checks.database') ?? "HTTP {$response->status()}");
        } catch (\Exception $e) {
            $detail = $e->getMessage();
        }

        if ($isHealthy && !$wasHealthy) {
            $discord->send('✅ Recovered — /health is responding normally again.', 'success');
            $this->info('Health check recovered.');
        } elseif (!$isHealthy && $wasHealthy) {
            $discord->send("Health check FAILED: {$detail}", 'error');
            $this->error("Health check failed: {$detail}");
        } else {
            $this->info($isHealthy ? 'Healthy (no change).' : 'Still failing (no repeat alert).');
        }

        Cache::forever(self::CACHE_KEY, $isHealthy);

        return $isHealthy ? 0 : 1;
    }
}
