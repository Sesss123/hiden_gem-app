<?php

namespace App\Console\Commands;

use App\Events\FeaturedListingsUpdated;
use App\Services\DiscordAlertService;
use App\Services\FirestoreService;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Cache;

class BroadcastMarketplaceUpdates extends Command
{
    protected $signature = 'marketplace:broadcast-updates';

    protected $description = 'Refresh the featured-listings cache and broadcast changes.';

    public function handle(FirestoreService $firestore, DiscordAlertService $discord): int
    {
        $all = $firestore->queryDocuments('guide_listings', 'isFeatured', 'EQUAL', true);
        $filtered = array_values(array_filter($all, fn ($listing) =>
            ($listing['status'] ?? '') === 'published' && ($listing['moderationStatus'] ?? '') === 'approved'
        ));
        usort($filtered, fn ($a, $b) => ($b['ratingAverage'] ?? 0) <=> ($a['ratingAverage'] ?? 0));
        $listings = array_slice($filtered, 0, 10);

        if ($this->looksLikeFetchFailure($all, $discord)) {
            return self::SUCCESS;
        }

        $this->broadcastIfChanged($listings);
        return self::SUCCESS;
    }

    private function looksLikeFetchFailure(array $freshResult, DiscordAlertService $discord): bool
    {
        if (!empty($freshResult)) {
            return false;
        }
        $existing = Cache::get('listings_featured');
        if (empty($existing)) {
            return false;
        }

        $message = 'BroadcastMarketplaceUpdates: Firestore returned no featured listings while the cache still contains data; preserving the current cache.';
        $this->warn($message);
        $discord->send($message, 'warning');
        return true;
    }

    private function broadcastIfChanged(array $listings): void
    {
        $newHash = md5(json_encode($listings));
        $previousHash = Cache::get('listings_featured_hash');
        Cache::put('listings_featured', $listings, 300);

        if ($newHash === $previousHash) {
            return;
        }

        Cache::put('listings_featured_hash', $newHash, 300);
        event(new FeaturedListingsUpdated($listings));
        $this->info('Featured listings changed; broadcast fired.');
    }
}
