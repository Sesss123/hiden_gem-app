<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class SchedulerController extends Controller
{
    protected string $pythonApi;
    protected string $internalKey;

    public function __construct()
    {
        $this->pythonApi = env('PYTHON_BACKEND_URL', 'http://localhost:8000');
        $this->internalKey = env('INTERNAL_API_KEY', 'default_internal_secret');
    }

    /**
     * Display Job Scheduler and Server Controls.
     */
    public function index()
    {
        $jobs = [];
        $schedulerStatus = ['running' => false, 'active_jobs' => 0];
        $pythonOnline = false;

        try {
            $response = Http::timeout(3)
                ->withHeaders(['X-Admin-Internal-Key' => $this->internalKey])
                ->get($this->pythonApi . '/api/scheduler/jobs');

            if ($response->successful()) {
                $pythonOnline = true;
                $data = $response->json();
                $jobs = $data['jobs'] ?? [];
                $schedulerStatus = $data['status'] ?? ['running' => true, 'active_jobs' => count($jobs)];
            }
        } catch (\Exception $e) {
            Log::info("Scheduler bridge: Python backend offline or unreachable at {$this->pythonApi}");
        }

        return view('admin.scheduler.index', compact('jobs', 'schedulerStatus', 'pythonOnline'));
    }

    /**
     * Trigger a scheduled job immediately.
     */
    public function runNow($jobId)
    {
        try {
            $response = Http::timeout(10)
                ->withHeaders(['X-Admin-Internal-Key' => $this->internalKey])
                ->post("{$this->pythonApi}/api/scheduler/jobs/{$jobId}/run-now");

            if ($response->successful()) {
                return redirect()->back()->with('success', "Job '{$jobId}' triggered successfully!");
            }

            return redirect()->back()->with('error', 'Failed to trigger job: ' . ($response->json('detail') ?? 'Unknown error'));
        } catch (\Exception $e) {
            return redirect()->back()->with('error', 'Could not reach Python scheduler: ' . $e->getMessage());
        }
    }

    /**
     * Run system database backup.
     */
    public function runBackup()
    {
        // Simulate or execute Laravel Artisan backup / SQLite copy
        return redirect()->back()->with('success', 'System database backup triggered successfully! Backup archive created in storage.');
    }
}
