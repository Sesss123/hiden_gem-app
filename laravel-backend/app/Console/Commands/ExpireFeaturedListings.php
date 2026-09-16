<?php

namespace App\Console\Commands;

use App\Services\DiscordAlertService;
use App\Services\FirestoreService;
use Illuminate\Console\Command;

/**
 * Flips isFeatured back to false on any guide_listings doc whose
 * featuredUntil has passed. Featuring is granted server-side by an admin
 * (GuideListingController::approve/setFeatured, stamping a featuredUntil —
 * see firestore.rules, which blocks clients from setting isFeatured
 * directly), but nothing else ever revisits that field — without this job a
 * listing stays featured forever once turned on.
 *
 * Scheduled daily in Console/Kernel.php.
 */
class ExpireFeaturedListings extends Command
{
    protected $signature = 'marketplace:expire-featured-listings';

    protected $description = 'Unfeature guide_listings whose featuredUntil has passed.';

    public function handle(FirestoreService $firestore, DiscordAlertService $discord): int
    {
        $featured = $firestore->queryDocuments('guide_listings', 'isFeatured', 'EQUAL', true);
        $now = now()->toIso8601String();

        $expiredCount = 0;
        $failedIds = [];
        foreach ($featured as $listing) {
            $featuredUntil = $listing['featuredUntil'] ?? null;
            if ($featuredUntil === null || $featuredUntil >= $now) {
                continue;
            }

            $synced = $firestore->patchDocument('guide_listings', $listing['id'], [
                'isFeatured' => false,
                'featuredUntil' => null,
            ]);
            if ($synced) {
                $expiredCount++;
            } else {
                $failedIds[] = $listing['id'];
            }
        }

        $this->info("Expired {$expiredCount} featured listing(s).");

        if (!empty($failedIds)) {
            $message = "ExpireFeaturedListings: failed to unfeature " . count($failedIds) . " listing(s): " . implode(', ', $failedIds);
            $this->error($message);
            $discord->send($message, 'error');
        }

        return self::SUCCESS;
    }
}
