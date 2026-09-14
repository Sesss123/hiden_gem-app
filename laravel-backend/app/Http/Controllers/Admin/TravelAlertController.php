<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\TravelAlert;
use App\Models\AdminAuditLog;
use App\Services\FirestoreService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class TravelAlertController extends Controller
{
    public function index(Request $request)
    {
        TravelAlert::where('is_active', true)->where('expires_at', '<', now())->update(['is_active' => false]);
        $alerts = TravelAlert::latest()->paginate(25);
        return $request->expectsJson()
            ? response()->json($alerts)
            : view('admin.travel-alerts.index', compact('alerts'));
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'type' => ['required', 'in:landslide,flood,closed_road,monsoon'],
            'level' => ['required', 'integer', 'between:1,3'],
            'title' => ['required', 'string', 'max:160'],
            'message' => ['required', 'string', 'max:4000'],
            'source' => ['required', 'string', 'max:120'],
            'districts' => ['nullable', 'array'],
            'river_basins' => ['nullable', 'array'],
            'hazard_geometry' => ['nullable', 'array'],
            'starts_at' => ['required', 'date'],
            'expires_at' => ['required', 'date', 'after:starts_at'],
        ]);
        $data['published_by'] = $request->user()->id;
        $data['is_active'] = false;
        $alert = TravelAlert::create($data);
        $this->audit($request, 'travel_alert.created', $alert);
        return $request->expectsJson()
            ? response()->json($alert, 201)
            : redirect()->route('admin.travel-alerts.index')->with('success', 'Alert draft created.');
    }

    public function update(Request $request, TravelAlert $travelAlert, FirestoreService $firestore)
    {
        $data = $request->validate([
            'type' => ['sometimes', 'in:landslide,flood,closed_road,monsoon'],
            'level' => ['sometimes', 'integer', 'between:1,3'],
            'title' => ['sometimes', 'string', 'max:160'],
            'message' => ['sometimes', 'string', 'max:4000'],
            'source' => ['sometimes', 'string', 'max:120'],
            'expires_at' => ['sometimes', 'date', 'after:now'],
            'districts' => ['nullable', 'array'],
            'river_basins' => ['nullable', 'array'],
            'hazard_geometry' => ['nullable', 'array'],
        ]);
        $oldLevel = $travelAlert->level;
        if ($travelAlert->is_active) {
            $mirror = array_merge($data, ['updatedAt' => now()->utc()->toIso8601String()]);
            if (isset($mirror['expires_at'])) {
                $mirror['expiresAt'] = \Carbon\Carbon::parse($mirror['expires_at'])->utc()->toIso8601String();
                unset($mirror['expires_at']);
            }
            abort_unless($firestore->patchDocument('travel_alerts', (string) $travelAlert->id, $mirror), 503, 'Firestore sync failed; alert was not updated.');
        }
        $travelAlert->update($data);
        if ($travelAlert->is_active && $travelAlert->level > $oldLevel) {
            $firestore->sendFcmTopic('travel_alerts', 'Travel alert escalated', $travelAlert->message, [
                'type' => 'travel_alert',
                'event' => 'escalated',
                'alertId' => (string) $travelAlert->id,
                'level' => (string) $travelAlert->level,
            ]);
        }
        $this->audit($request, 'travel_alert.updated', $travelAlert);
        return $request->expectsJson() ? response()->json($travelAlert->fresh()) : back()->with('success', 'Alert updated.');
    }

    public function publish(Request $request, TravelAlert $travelAlert, FirestoreService $firestore)
    {
        abort_if($travelAlert->expires_at->isPast(), 422, 'Cannot publish an expired alert.');
        abort_if(!$travelAlert->source, 422, 'A verified source is required.');

        $duplicate = TravelAlert::where('id', '!=', $travelAlert->id)
            ->where('is_active', true)->where('type', $travelAlert->type)
            ->where('title', $travelAlert->title)->where('expires_at', '>', now())->exists();
        abort_if($duplicate, 409, 'A matching active alert already exists.');

        $payload = $travelAlert->toArray();
        $payload['startsAt'] = $travelAlert->starts_at->utc()->toIso8601String();
        $payload['expiresAt'] = $travelAlert->expires_at->utc()->toIso8601String();
        $payload['updatedAt'] = now()->utc()->toIso8601String();
        $payload['isActive'] = true;

        abort_unless($firestore->patchDocument('travel_alerts', (string) $travelAlert->id, $payload), 503, 'Firestore sync failed; alert was not published.');
        DB::transaction(function () use ($travelAlert) {
            $travelAlert->update(['is_active' => true]);
        });
        $firestore->sendFcmTopic('travel_alerts', $travelAlert->title, $travelAlert->message, [
            'alertId' => (string) $travelAlert->id,
            'type' => 'travel_alert',
            'alertType' => $travelAlert->type,
            'event' => 'published',
            'level' => (string) $travelAlert->level,
            'source' => $travelAlert->source,
            'expiresAt' => $travelAlert->expires_at->utc()->toIso8601String(),
        ]);
        $this->audit($request, 'travel_alert.published', $travelAlert);
        return $request->expectsJson() ? response()->json($travelAlert->fresh()) : back()->with('success', 'Alert published.');
    }

    public function destroy(Request $request, TravelAlert $travelAlert, FirestoreService $firestore)
    {
        if ($travelAlert->is_active) {
            abort_unless($firestore->patchDocument('travel_alerts', (string) $travelAlert->id, [
                'isActive' => false,
                'updatedAt' => now()->utc()->toIso8601String(),
            ]), 503, 'Firestore sync failed; alert was not deactivated.');
        }
        $travelAlert->update(['is_active' => false]);
        $this->audit($request, 'travel_alert.deactivated', $travelAlert);
        return $request->expectsJson() ? response()->noContent() : back()->with('success', 'Alert deactivated.');
    }

    private function audit(Request $request, string $action, TravelAlert $alert): void
    {
        $user = $request->user();
        AdminAuditLog::create([
            'user_id' => $user?->id,
            'actor_name' => $user?->name,
            'actor_email' => $user?->email,
            'action' => $action,
            'target_type' => TravelAlert::class,
            'target_id' => (string) $alert->id,
            'details' => ['type' => $alert->type, 'level' => $alert->level, 'source' => $alert->source],
            'ip_address' => $request->ip(),
            'created_at' => now(),
        ]);
    }
}
