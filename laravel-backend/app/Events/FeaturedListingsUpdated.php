<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

/**
 * Broadcast on the public `featured-listings` channel whenever the cached
 * featured-guides payload (MarketplaceController::featured()) changes.
 * Lets connected clients update instantly instead of waiting out the 5-min
 * HTTP cache window — MarketplaceRepository.getFeaturedGuides() keeps that
 * HTTP path as the initial-load + offline fallback.
 */
class FeaturedListingsUpdated implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    /** @param array<int, array<string, mixed>> $listings */
    public function __construct(public array $listings)
    {
    }

    public function broadcastOn(): array
    {
        return [new Channel('featured-listings')];
    }

    public function broadcastAs(): string
    {
        return 'FeaturedListingsUpdated';
    }

    /** @return array<string, mixed> */
    public function broadcastWith(): array
    {
        return ['listings' => $this->listings];
    }
}
