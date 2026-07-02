<?php

namespace App\Console\Commands;

use App\Models\Place;
use App\Models\PlaceImage;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class MigratePlaceIds extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'places:migrate-ids';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Convert existing random or legacy place IDs in MySQL to Smart Semantic IDs (e.g. WF-MAT-001)';

    /**
     * Execute the console command.
     *
     * @return int
     */
    public function handle()
    {
        $this->info('Starting migration of Place IDs to Smart Semantic format (e.g. WF-MAT-001)...');

        $places = Place::orderBy('category')->orderBy('district')->orderBy('id')->get();
        $total = $places->count();
        $converted = 0;
        $skipped = 0;

        $catMap = [
            'waterfalls' => 'WF',
            'beach' => 'BE',
            'religious places' => 'TM',
            'temple' => 'TM',
            'sacred temple' => 'TM',
            'view point' => 'VP',
            'tea estate' => 'TE',
            'adventure park' => 'AP',
            'ancient architecture' => 'ARC',
            'colonial fort' => 'CF',
            'royal palace' => 'RP',
            'historical monument' => 'HM',
            'wildlife / national park' => 'WL',
            'hiking / trekking' => 'HK',
            'village experience' => 'VE',
            'culinary / food' => 'FD',
            'cultural site' => 'CS',
        ];

        $counters = [];

        foreach ($places as $place) {
            $oldId = $place->id;

            // Check if already in Smart Semantic format (e.g., WF-MAT-001 or ARC-COL-012)
            if (preg_match('/^[A-Z]{2,4}-[A-Z]{3}-\d{3}$/', $oldId)) {
                $skipped++;
                continue;
            }

            $catKey = strtolower(trim($place->category));
            $catCode = $catMap[$catKey] ?? strtoupper(substr(preg_replace('/[^a-zA-Z]/', '', $place->category), 0, 3));
            if (empty($catCode)) $catCode = 'GEM';

            $distCode = strtoupper(substr(preg_replace('/[^a-zA-Z]/', '', $place->district), 0, 3));
            if (empty($distCode)) $distCode = 'SL';

            $prefix = "{$catCode}-{$distCode}-";
            
            if (!isset($counters[$prefix])) {
                // Initialize counter by checking existing IDs with this prefix
                $lastPlace = DB::table('places')
                    ->where('id', 'like', "{$prefix}%")
                    ->where('id', '!=', $oldId)
                    ->orderBy('id', 'desc')
                    ->first();

                $nextNum = 1;
                if ($lastPlace && preg_match('/-(\d+)$/', $lastPlace->id, $matches)) {
                    $nextNum = ((int)$matches[1]) + 1;
                }
                $counters[$prefix] = $nextNum;
            }

            $newId = $prefix . sprintf('%03d', $counters[$prefix]);
            $counters[$prefix]++;

            // Ensure uniqueness if collision happens
            while (DB::table('places')->where('id', $newId)->where('id', '!=', $oldId)->exists()) {
                $counters[$prefix]++;
                $newId = $prefix . sprintf('%03d', $counters[$prefix]);
            }

            DB::beginTransaction();
            try {
                // 1. Update place_images foreign key
                DB::table('place_images')->where('place_id', $oldId)->update(['place_id' => $newId]);

                // 2. Update places primary key
                DB::table('places')->where('id', $oldId)->update(['id' => $newId]);

                DB::commit();
                $converted++;
            } catch (\Exception $e) {
                DB::rollBack();
                $this->error("Failed to migrate ID for {$oldId}: " . $e->getMessage());
            }
        }

        $this->info("Migration Complete! Converted: {$converted} places, Skipped (already smart): {$skipped} places.");
        return 0;
    }
}
