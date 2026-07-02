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
        $key = env('INTERNAL_API_KEY', 'default_internal_secret');
        if (app()->environment('production') && $key === 'default_internal_secret') {
            throw new \RuntimeException("CRITICAL: INTERNAL_API_KEY must be configured in production environment.");
        }
        $this->internalKey = $key;
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

    /**
     * Trigger 3D AR Model & Vision Validator via Python /api/pipeline/vision-analyze.
     */
    public function visionAnalyze(Request $request)
    {
        $request->validate([
            'image_url' => 'required|url|max:1000',
            'place_name' => 'nullable|string|max:255',
            'ar_model_id' => 'nullable|string|max:100',
        ]);

        try {
            $response = Http::timeout(15)
                ->withHeaders(['X-Admin-Internal-Key' => $this->internalKey])
                ->post($this->pythonApi . '/api/pipeline/vision-analyze', [
                    'image_url' => $request->image_url,
                    'place_name' => $request->place_name ?? 'AR Heritage Model',
                ]);

            if ($response->successful()) {
                $data = $response->json();
                $modelId = $request->ar_model_id ?: 'gem_' . rand(1000, 9999);
                $qrUrl = "https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=" . urlencode("hiddengemssl://ar-viewer?model_id=" . $modelId . "&asset=" . $request->image_url);
                
                $data['qr_preview'] = $qrUrl;
                $data['model_id'] = $modelId;

                return redirect()->back()->with('vision_result', $data)->with('success', 'AI Vision Analysis & QR Code Signage generated successfully!');
            }

            return redirect()->back()->with('error', 'Python Vision API Error: ' . ($response->json('detail') ?? $response->body()));
        } catch (\Exception $e) {
            return redirect()->back()->with('error', 'Failed to reach Python Vision Backend: ' . $e->getMessage());
        }
    }

    /**
     * Trigger Emergency Monsoon/Weather Broadcast via Python /api/weather/broadcast.
     */
    public function emergencyBroadcast(Request $request)
    {
        $request->validate([
            'district' => 'required|string|max:100',
            'message' => 'required|string|max:500',
            'severity' => 'required|string|in:WARNING,CRITICAL,EMERGENCY',
        ]);

        try {
            $response = Http::timeout(10)
                ->withHeaders(['X-Admin-Internal-Key' => $this->internalKey])
                ->post($this->pythonApi . '/api/weather/broadcast', [
                    'district' => $request->district,
                    'message' => $request->message,
                    'severity' => $request->severity,
                ]);

            if ($response->successful()) {
                return redirect()->back()->with('success', "🚨 Emergency Broadcast dispatched to {$request->district} via Reverb Push Engine!");
            }

            return redirect()->back()->with('error', 'Python Weather API Error: ' . ($response->json('detail') ?? $response->body()));
        } catch (\Exception $e) {
            return redirect()->back()->with('error', 'Failed to reach Python Weather Backend: ' . $e->getMessage());
        }
    }
}
