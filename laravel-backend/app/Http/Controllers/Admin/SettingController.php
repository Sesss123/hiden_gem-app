<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\AppSetting;
use App\Models\AdminAuditLog;
use App\Services\FirestoreService;
use App\Traits\LogsAdminActivity;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class SettingController extends Controller
{
    use LogsAdminActivity;

    /**
     * Display the application settings screen.
     */
    public function index()
    {
        $adsSetting = null;
        $isAdsEnabled = false;

        try {
            $adsSetting = AppSetting::with('updater')->where('key', 'ads_enabled')->first();
            if ($adsSetting) {
                $isAdsEnabled = filter_var($adsSetting->value, FILTER_VALIDATE_BOOLEAN);
            }
        } catch (\Throwable $e) {
            // Fail closed while settings storage is unavailable.
        }

        $recentSettingsLogs = collect();
        try {
            $recentSettingsLogs = AdminAuditLog::where('action', 'like', '%setting%')
                ->orWhere('action', 'like', '%ads%')
                ->orderBy('created_at', 'desc')
                ->take(10)
                ->get();
        } catch (\Throwable $e) {
            // Fallback gracefully
        }

        return view('admin.settings.index', compact('adsSetting', 'isAdsEnabled', 'recentSettingsLogs'));
    }

    /**
     * Toggle or update the mobile ads master switch.
     */
    public function toggleAds(Request $request, FirestoreService $firebase)
    {
        $user = auth()->user();
        if (!$user || !$user->isFullAdmin()) {
            abort(403, 'Unauthorized. Only Full Administrators can toggle mobile advertisements.');
        }

        $newState = $request->boolean('enabled');

        $previousState = AppSetting::isAdsEnabled();
        $setting = DB::transaction(function () use ($newState, $previousState, $user) {
            $setting = AppSetting::set(
                'ads_enabled',
                $newState,
                $user->id,
                'boolean',
                'Master switch for Google AdMob mobile advertisements across Android and iOS apps.'
            );

            // The setting and its audit record commit together. If audit
            // persistence fails, the toggle is rolled back instead of
            // returning an unaudited success response.
            $this->logAdminAction(
                'toggle_ads_master_switch',
                'app_settings',
                $setting->id,
                [
                    'previous' => $previousState,
                    'new' => $newState,
                    'status_label' => $newState ? 'ENABLED (ON)' : 'DISABLED (OFF)',
                ]
            );
            return $setting;
        });

        // Near-real-time refresh for running apps. Polling/resume sync remains
        // the delivery fallback when FCM is unavailable or permission is denied.
        $pushed = $firebase->sendFcmTopic('app_config', 'App configuration updated', 'Advertising configuration changed.', [
            'type' => 'app_config',
            'key' => 'ads_enabled',
            'enabled' => $newState ? 'true' : 'false',
        ], false);
        if (!$pushed) {
            Log::warning('Ads-toggle config-change push failed — clients will pick up the change on their next poll/resume instead.');
        }

        if ($request->wantsJson()) {
            return response()->json([
                'success' => true,
                'enabled' => $newState,
                'message' => 'Mobile Ads setting updated successfully.',
            ]);
        }

        return redirect()->back()->with('success', 'Mobile advertisements status updated: ' . ($newState ? 'ON (Active)' : 'OFF (Paused)'));
    }
}
