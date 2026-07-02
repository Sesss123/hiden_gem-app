<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/*
|--------------------------------------------------------------------------
| Console Routes & Task Scheduler (Phase 5)
|--------------------------------------------------------------------------
|
| This file defines all closure-based console commands and schedules
| automated background jobs such as the AI Harvester and Monsoon Monitor.
|
*/

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

/**
 * 🤖 Phase 5 Automated AI Curation Pipeline Trigger (CRON Job)
 * Schedules automated curation and data enrichment via Python FastAPI during off-peak hours (2:00 AM).
 */
Artisan::command('ai:harvest-pipeline {mode=full}', function ($mode) {
    $this->info("⚡ Starting Automated AI Harvester Pipeline [Mode: {$mode}]...");
    
    $pythonApi = env('PYTHON_AI_SERVICE_URL', 'http://localhost:8000');
    $internalKey = env('INTERNAL_API_KEY', 'YOUR_32_CHAR_INTERNAL_API_KEY_HERE');

    try {
        $response = Http::timeout(60)
            ->withHeaders(['X-Admin-Internal-Key' => $internalKey])
            ->post($pythonApi . '/api/pipeline/trigger', [
                'mode' => $mode,
                'initiated_by' => 'laravel-cron-scheduler',
                'timestamp' => now()->toIso8601String(),
            ]);

        if ($response->successful()) {
            $this->info("✅ AI Harvester Pipeline successfully triggered: " . json_encode($response->json()));
            Log::info("CRON: AI Harvester Pipeline completed successfully.", $response->json() ?? []);
        } else {
            $this->error("❌ Pipeline Trigger Failed: HTTP " . $response->status() . " - " . $response->body());
            Log::error("CRON: AI Harvester Pipeline failed.", ['status' => $response->status(), 'body' => $response->body()]);
        }
    } catch (\Exception $e) {
        $this->error("🚨 Error reaching Python AI Microservice: " . $e->getMessage());
        Log::error("CRON: AI Harvester Exception.", ['error' => $e->getMessage()]);
    }
})->purpose('Trigger Python AI Curation Pipeline for automated hidden gem harvesting');

/**
 * 🌧️ Phase 5 Automated Monsoon Hazard Monitor (CRON Job)
 * Checks Sri Lankan district weather alerts every hour and dispatches WebSocket push broadcasts if critical hazards are detected.
 */
Artisan::command('ai:monsoon-monitor', function () {
    $this->info("🌧️ Checking Sri Lankan District Monsoon Hazards...");
    
    $pythonApi = env('PYTHON_AI_SERVICE_URL', 'http://localhost:8000');
    $internalKey = env('INTERNAL_API_KEY', 'YOUR_32_CHAR_INTERNAL_API_KEY_HERE');

    try {
        $response = Http::timeout(10)->get($pythonApi . '/api/weather/alerts');
        if ($response->successful()) {
            $alerts = $response->json('alerts', []);
            $criticalFound = 0;

            foreach ($alerts as $alert) {
                if (($alert['hazard_level'] ?? '') === 'ALERT') {
                    $criticalFound++;
                    $district = $alert['district'];
                    $advice = $alert['advice'];

                    $this->warn("⚠️ CRITICAL MONSOON HAZARD IN {$district}: {$advice}");
                    
                    // Trigger emergency broadcast automatically
                    Http::timeout(10)
                        ->withHeaders(['X-Admin-Internal-Key' => $internalKey])
                        ->post($pythonApi . '/api/weather/broadcast', [
                            'district' => $district,
                            'message' => "AUTOMATED WEATHER ALERT: {$advice}",
                            'severity' => 'CRITICAL',
                        ]);
                }
            }
            $this->info("✅ Monsoon check complete. Critical alerts dispatched: {$criticalFound}");
        }
    } catch (\Exception $e) {
        $this->error("🚨 Monsoon Monitor Error: " . $e->getMessage());
    }
})->purpose('Monitor live monsoon weather hazards and dispatch automatic emergency push broadcasts');
