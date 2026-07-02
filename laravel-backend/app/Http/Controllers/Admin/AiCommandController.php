<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class AiCommandController extends Controller
{
    protected string $pythonApi;
    protected string $internalKey;

    public function __construct()
    {
        $this->pythonApi = env('PYTHON_BACKEND_URL', 'http://localhost:8000');
        $this->internalKey = env('INTERNAL_API_KEY', 'default_internal_secret');
    }

    /**
     * Display AI Command Center & Pipeline Monitor.
     */
    public function index()
    {
        $pythonOnline = false;
        $stats = [
            'status' => 'Offline',
            'version' => 'N/A',
            'active_models' => ['Gemini 2.0 Flash', 'Lumen AI Neural', 'Vision Guardian V2']
        ];

        try {
            $response = Http::timeout(2)->get($this->pythonApi . '/');
            if ($response->successful()) {
                $pythonOnline = true;
                $data = $response->json();
                $stats['status'] = 'Online & Ready';
                $stats['version'] = $data['version'] ?? '2.5.0-hardened';
            }
        } catch (\Exception $e) {
            Log::warning("AI Command Center: Could not connect to Python backend at {$this->pythonApi}");
        }

        return view('admin.ai-command.index', compact('pythonOnline', 'stats'));
    }

    /**
     * Trigger Neural AI Discovery job.
     */
    public function triggerDiscovery(Request $request)
    {
        $request->validate([
            'prompt' => 'required|string|max:500',
        ]);

        try {
            $response = Http::timeout(10)
                ->withHeaders(['X-Admin-Internal-Key' => $this->internalKey])
                ->post($this->pythonApi . '/api/pipeline/discover', [
                    'prompt' => $request->prompt,
                ]);

            if ($response->successful()) {
                return redirect()->back()->with('success', 'Neural AI Discovery job initiated successfully via Python Subsystem!');
            }

            return redirect()->back()->with('error', 'Python API Error: ' . ($response->json('detail') ?? $response->body()));
        } catch (\Exception $e) {
            return redirect()->back()->with('error', 'Failed to reach Python AI Backend: ' . $e->getMessage());
        }
    }

    /**
     * Trigger Smart URL Intake harvesting job.
     */
    public function harvestIntake(Request $request)
    {
        $request->validate([
            'url' => 'required|url|max:500',
        ]);

        try {
            $response = Http::timeout(10)
                ->withHeaders(['X-Admin-Internal-Key' => $this->internalKey])
                ->post($this->pythonApi . '/api/pipeline/smart-intake', [
                    'url' => $request->url,
                ]);

            if ($response->successful()) {
                return redirect()->back()->with('success', 'Smart URL Intake job initiated successfully!');
            }

            return redirect()->back()->with('error', 'Python API Error: ' . ($response->json('detail') ?? $response->body()));
        } catch (\Exception $e) {
            return redirect()->back()->with('error', 'Failed to reach Python AI Backend: ' . $e->getMessage());
        }
    }
}
