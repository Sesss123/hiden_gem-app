<?php

namespace App\Console\Commands;

use App\Models\Place;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\File;

class ImportPlaces extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'places:import {path? : Optional path to JSON file}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Import legacy JSON place records into MySQL via Eloquent Observers';

    /**
     * Execute the console command.
     *
     * @return int
     */
    public function handle()
    {
        // Passed by reference into generateSmartId() below and accumulates
        // per category+district sequence numbers across the whole import
        // run — must be declared before the loop, not left to PHP's
        // reference auto-vivification (works today, but emits a deprecation
        // notice on stricter PHP versions and reads as a bug at a glance).
        $counters = [];

        $inputPath = $this->argument('path');

        if ($inputPath) {
            $files = [$inputPath];
        } else {
            $files = File::glob(base_path('../assets/tripme_database_complete_*.json'));
        }

        if (empty($files)) {
            $this->error("No JSON data files found!");
            $this->info("Please specify exact path: php artisan places:import /path/to/data.json");
            return 1;
        }

        $totalCount = 0;

        foreach ($files as $path) {
            if (!File::exists($path)) {
                $this->error("File not found: {$path}");
                continue;
            }

            $this->info("Loading file: " . basename($path));
            $json = File::get($path);
            
            // Fix concatenated JSON objects commonly found in loosely formatted .jsonl files
            $jsonStr = trim($json);
            if (str_starts_with($jsonStr, '{') && str_ends_with($jsonStr, '}')) {
                $jsonStr = preg_replace('/\}\s*\{/', '},{', $jsonStr);
                $jsonStr = '[' . $jsonStr . ']';
            }

            $data = json_decode($jsonStr, true);

            if (!is_array($data)) {
                $this->error("Invalid JSON format in {$path}");
                continue;
            }

            $count = 0;
            foreach ($data as $item) {
                $rawId = $item['id'] ?? ('hg_' . uniqid());
                $category = $item['category'] ?? $item['category_id'] ?? 'General';
                $district = $item['district'] ?? $item['district_id'] ?? 'Unknown';

                if (preg_match('/^[A-Z]{2,4}-[A-Z]{3}-\d{3}$/', $rawId)) {
                    $id = $rawId;
                } else {
                    $id = $this->generateSmartId($category, $district, $counters);
                }

                // Map legacy LLM JSON fields or new camelCase fields
                Place::updateOrCreate(
                    ['id' => $id],
                    [
                    'name' => $item['name'] ?? 'Unnamed Gem',
                    'description' => $item['description'] ?? '',
                    'district' => $item['district'] ?? $item['district_id'] ?? 'Unknown',
                    'province' => $item['province'] ?? $item['province_id'] ?? '',
                    'category' => $item['category'] ?? $item['category_id'] ?? 'General',
                    'lat' => (float) ($item['lat'] ?? 0),
                    'lng' => (float) ($item['lng'] ?? 0),
                    'rating' => (float) ($item['rating'] ?? 4.5),
                    'ticket_price' => $item['ticket_price'] ?? $item['ticketRange'] ?? 'Free',
                    'road_condition' => $item['road_condition'] ?? $item['roadType'] ?? 'Unknown',
                    'vehicle_access' => $item['vehicleAccess'] ?? $item['vehicle_access'] ?? '',
                    'opening_hours' => $item['opening_hours'] ?? $item['openingHours'] ?? '',
                    'mobile_signal' => $item['mobile_signal'] ?? '',
                    'activities' => $item['activities'] ?? '',
                    'tourist_popularity' => $item['tourist_popularity'] ?? '',
                    'family_friendly' => $item['family_friendly'] ?? '',
                    'budget_category' => $item['budget_category'] ?? $item['budgetCategory'] ?? '',
                    'parking_avail' => $item['parking_avail'] ?? '',
                    'parking_range' => $item['parkingRange'] ?? ($item['parking_avail'] === 'yes' ? 'Available' : 'No'),
                    'toilets' => $item['toilets'] ?? '',
                    'food_nearby' => $item['food_nearby'] ?? '',
                    'wheelchair_access' => $item['wheelchair_access'] ?? '',
                    'camping_allowed' => $item['camping_allowed'] ?? '',
                    'safety_level' => $item['safety_level'] ?? $item['safetyLevel'] ?? '',
                    'wildlife_hazard' => $item['wildlife_hazard'] ?? '',
                    'guide_required' => $item['guide_required'] ?? '',
                    'rain_sensitivity' => $item['rain_sensitivity'] ?? '',
                    'monsoon_note' => $item['monsoon_note'] ?? '',
                    'best_time_to_visit' => $item['best_time_to_visit'] ?? $item['bestTime'] ?? 'Anytime',
                    'height_m' => $item['Height_m'] ?? $item['height_m'] ?? '0',
                    'length_km' => $item['Length_km'] ?? $item['length_km'] ?? '0',
                    'surfing' => $item['Surfing'] ?? $item['surfing'] ?? 'no',
                    'risk_tags' => is_array($item['riskTags'] ?? null) ? $item['riskTags'] : [],
                    'facilities' => is_array($item['facilities'] ?? null) ? $item['facilities'] : [],
                    'ar_supported' => (bool) ($item['arSupported'] ?? false),
                    'ar_tier' => (int) ($item['arTier'] ?? 3),
                    'ar_brand_name' => $item['arBrandName'] ?? '',
                    'ar_model_url' => $item['arModelUrl'] ?? '',
                    'ar_historical_model_url' => $item['arHistoricalModelUrl'] ?? '',
                    'ar_model_scale' => (float) ($item['arModelScale'] ?? 0.01),
                    'historical_period' => $item['historicalPeriod'] ?? '',
                    'ar_file_size_mb' => (float) ($item['ar_file_size_mb'] ?? 0),
                    'audio_guide_url_si' => $item['audio_guide_url_si'] ?? '',
                    'audio_guide_url_en' => $item['audio_guide_url_en'] ?? '',
                    'geohash' => $item['geohash'] ?? '',
                    'image_url' => $item['imageUrl'] ?? null,
                ]);

                $count++;
                $totalCount++;
            }

            $this->info("Imported {$count} places from " . basename($path));
        }

        $this->info("Successfully imported a total of {$totalCount} places! Each assigned a sequential sync_version.");
        return 0;
    }

    protected function generateSmartId($category, $district, &$counters)
    {
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

        $catKey = strtolower(trim($category));
        $catCode = $catMap[$catKey] ?? strtoupper(substr(preg_replace('/[^a-zA-Z]/', '', $category), 0, 3));
        if (empty($catCode)) $catCode = 'GEM';

        $distCode = strtoupper(substr(preg_replace('/[^a-zA-Z]/', '', $district), 0, 3));
        if (empty($distCode)) $distCode = 'SL';

        $prefix = "{$catCode}-{$distCode}-";
        
        if (!isset($counters[$prefix])) {
            $lastPlace = Place::where('id', 'like', "{$prefix}%")
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

        while (Place::where('id', $newId)->exists()) {
            $counters[$prefix]++;
            $newId = $prefix . sprintf('%03d', $counters[$prefix]);
        }

        return $newId;
    }
}
