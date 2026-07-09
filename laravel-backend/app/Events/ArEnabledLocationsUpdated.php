<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

/**
 * Broadcast on the public `ar-enabled-locations` channel whenever the cached
 * AR-enabled locations payload (MarketplaceController::arEnabledLocations())
 * changes. Lets connected clients update instantly instead of waiting out the
 * 10-min HTTP cache window — ARVideoRepository.getAllEnabled() keeps that
 * HTTP path as the initial-load + offline fallback.
 */
class ArEnabledLocationsUpdated implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    /** @param array<int, array<string, mixed>> $locations */
    public function __construct(public array $locations)
    {
    }

    public function broadcastOn(): array
    {
        return [new Channel('ar-enabled-locations')];
    }

    public function broadcastAs(): string
    {
        return 'ArEnabledLocationsUpdated';
    }

    /** @return array<string, mixed> */
    public function broadcastWith(): array
    {
        return ['locations' => $this->locations];
    }
}
