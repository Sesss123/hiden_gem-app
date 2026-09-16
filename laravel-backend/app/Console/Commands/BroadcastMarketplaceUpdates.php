<?php

namespace App\Console\Commands;

use App\Events\ArEnabledLocationsUpdated;
use App\Events\FeaturedListingsUpdated;
use App\Services\DiscordAlertService;
use App\Services\FirestoreService;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Cache;

/**
 * Refreshes the two hot-read Marketplace/AR reference caches from Firestore
 * and broadcasts an update event over Reverb only when the payload actually
 * changed since the last run. This is the write side of the WebSocket relay:
 * MarketplaceController::featured()/arEnabledLocations() still serve the
 * cached values on every HTTP request (unchanged, still 1 Firestore read per
 * cache window), while this command is what keeps that cache warm AND
 * pushes live updates to connected clients — so Firestore read cost stays
 * exactly what it already was (Round 1 / R9 of the cost-reduction work),
 * with push delivery layered on top instead of clients waiting for the next
 * HTTP GET after their local cache expires.
 *
 * Scheduled to run every 5 minutes in Console/Kernel.php, matching the
 * shorter of the two HTTP cache windows (featured: 5 min, AR: 10 min) so
 * neither cache is ever served meaningfully stale.
 */
class BroadcastMarketplaceUpdates extends Command
{
    protected $signature = 'marketplace:broadcast-updates';

    protected $description = 'Refresh featured-listings and AR-enabled-locations caches from Firestore, broadcasting an update only when the data actually changed.';

    public function handle(FirestoreService $firestore, DiscordAlertService $discord): int
    {
        $this->refreshFeaturedListings($firestore, $discord);
        $this->refreshArEnabledLocations($firestore, $discord);

        return self::SUCCESS;
    }

    private function refreshFeaturedListings(FirestoreService $firestore, DiscordAlertService $discord): void
    {
        $all = $firestore->queryDocuments('guide_listings', 'isFeatured', 'EQUAL', true);
        $filtered = array_values(array_filter($all, fn ($l) =>
            ($l['status'] ?? '') === 'published' && ($l['moderationStatus'] ?? '') === 'approved'
        ));
        usort($filtered, fn ($a, $b) => ($b['ratingAverage'] ?? 0) <=> ($a['ratingAverage'] ?? 0));
        $listings = array_slice($filtered, 0, 10);

        if ($this->looksLikeFetchFailure($all, 'listings_featured', $discord, 'featured listings')) {
            return;
        }

        $this->broadcastIfChanged('listings_featured', 'listings_featured_hash', $listings, function (array $data) {
            event(new FeaturedListingsUpdated($data));
        });
    }

    private function refreshArEnabledLocations(FirestoreService $firestore, DiscordAlertService $discord): void
    {
        $all = $firestore->listDocuments('locations');
        $locations = array_values(array_filter($all, fn ($l) => !empty($l['videoUrl'] ?? '')));

        if ($this->looksLikeFetchFailure($all, 'ar_enabled_locations', $discord, 'AR-enabled locations')) {
            return;
        }

        $this->broadcastIfChanged('ar_enabled_locations', 'ar_enabled_locations_hash', $locations, function (array $data) {
            event(new ArEnabledLocationsUpdated($data));
        });
    }

    /**
     * FirestoreService's query/list methods catch their own exceptions and
     * return [] on failure — indistinguishable from a genuine empty result.
     * If Firestore came back empty but the cache we're about to overwrite
     * currently holds data, that's very unlikely to be legitimate (going
     * from N featured listings to 0 within one 5-minute window) and far
     * more likely a transient Firestore outage. Skip the overwrite/broadcast
     * in that case rather than wiping a good cache and pushing an empty
     * state to every connected client.
     */
    private function looksLikeFetchFailure(array $freshResult, string $cacheKey, DiscordAlertService $discord, string $label): bool
    {
        if (!empty($freshResult)) {
            return false;
        }
        $existing = Cache::get($cacheKey);
        if (empty($existing)) {
            return false; // Genuinely empty before too — nothing to protect.
        }

        $message = "BroadcastMarketplaceUpdates: Firestore returned empty {$label} while cache still holds " . count($existing) . " item(s) — likely a fetch failure, skipping cache overwrite/broadcast this run.";
        $this->warn($message);
        $discord->send($message, 'warning');
        return true;
    }

    /**
     * Writes $data into the same cache key the HTTP endpoint reads
     * (Cache::remember short-circuits on the next request since the key is
     * now warm), and fires $onChanged only if $data differs from the last
     * run — determined by comparing a hash, not the cache TTL, so a
     * same-content refresh never triggers a spurious push.
     */
    private function broadcastIfChanged(string $cacheKey, string $hashKey, array $data, callable $onChanged): void
    {
        $newHash = md5(json_encode($data));
        $previousHash = Cache::get($hashKey);

        // Match the HTTP endpoint's own cache TTL (5 min for listings, 10 min
        // for AR) so this command and the lazy Cache::remember() path never
        // disagree on freshness.
        $ttl = $cacheKey === 'listings_featured' ? 300 : 600;
        Cache::put($cacheKey, $data, $ttl);

        if ($newHash === $previousHash) {
            return;
        }

        Cache::put($hashKey, $newHash, $ttl);
        $onChanged($data);
        $this->info("{$cacheKey} changed — broadcast fired (" . count($data) . ' items).');
    }
}
