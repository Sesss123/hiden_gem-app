<?php

namespace App\Console\Commands;

use App\Models\AdminAuditLog;
use App\Models\TravelAlert;
use App\Services\FirestoreService;
use Illuminate\Console\Command;

class ExpireTravelAlerts extends Command
{
    protected $signature = 'travel-alerts:expire';
    protected $description = 'Deactivate expired travel alerts and notify clients';

    public function handle(FirestoreService $firestore): int
    {
        TravelAlert::where('is_active', true)->where('expires_at', '<=', now())
            ->orderBy('id')->chunkById(100, function ($alerts) use ($firestore) {
                foreach ($alerts as $alert) {
                    if (!$firestore->patchDocument('travel_alerts', (string) $alert->id, [
                        'isActive' => false,
                        'updatedAt' => now()->utc()->toIso8601String(),
                    ])) {
                        $this->error("Firestore sync failed for alert {$alert->id}; retained active state for retry.");
                        continue;
                    }
                    $alert->update(['is_active' => false]);
                    $firestore->sendFcmTopic('travel_alerts', 'Travel alert ended', $alert->title, [
                        'alertId' => (string) $alert->id,
                        'event' => 'expired',
                    ]);
                    AdminAuditLog::create([
                        'action' => 'travel_alert.expired',
                        'target_type' => TravelAlert::class,
                        'target_id' => (string) $alert->id,
                        'details' => ['source' => $alert->source],
                        'created_at' => now(),
                    ]);
                }
            });
        return self::SUCCESS;
    }
}
