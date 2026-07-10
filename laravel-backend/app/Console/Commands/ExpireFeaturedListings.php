<?php

namespace App\Console\Commands;

use App\Services\FirestoreService;
use Illuminate\Console\Command;

/**
 * Flips isFeatured back to false on any guide_listings doc whose
 * featuredUntil has passed. Featuring is granted client-side (Pro/Elite
 * guides toggle it on in guide_listing_editor_screen.dart, which stamps a
 * 30-day featuredUntil), but nothing else ever revisits that field — without
 * this job a listing stays featured forever once turned on.
 *
 * Scheduled daily in Console/Kernel.php.
 */
class ExpireFeaturedListings extends Command
{
    protected $signature = 'marketplace:expire-featured-listings';

    protected $description = 'Unfeature guide_listings whose featuredUntil has passed.';

    public function handle(FirestoreService $firestore): int
    {
        $featured = $firestore->queryDocuments('guide_listings', 'isFeatured', 'EQUAL', true);
        $now = now()->toIso8601String();

        $expiredCount = 0;
        foreach ($featured as $listing) {
            $featuredUntil = $listing['featuredUntil'] ?? null;
            if ($featuredUntil === null || $featuredUntil >= $now) {
                continue;
            }

            $firestore->patchDocument('guide_listings', $listing['id'], [
                'isFeatured' => false,
                'featuredUntil' => null,
            ]);
            $expiredCount++;
        }

        $this->info("Expired {$expiredCount} featured listing(s).");

        return self::SUCCESS;
    }
}
