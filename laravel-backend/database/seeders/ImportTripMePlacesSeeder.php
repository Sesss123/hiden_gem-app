<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Place;
use Illuminate\Support\Str;

class ImportTripMePlacesSeeder extends Seeder
{
    public function run()
    {
        $files = glob(database_path('seeders/tripme_json/*.json'));

        $imported = 0;
        $skipped = 0;

        foreach ($files as $file) {
            $rows = json_decode(file_get_contents($file), true);
            if (!is_array($rows)) {
                continue;
            }

            foreach ($rows as $row) {
                $id = $row['id'] ?? null;
                if (!$id || !isset($row['name'])) {
                    $skipped++;
                    continue;
                }

                Place::updateOrCreate(
                    ['id' => $id],
                    [
                        'name' => $row['name'],
                        'description' => $row['description'] ?? null,
                        'district' => $row['district_id'] ?? 'Unknown',
                        'province' => $row['province_id'] ?? null,
                        'category' => $row['category_id'] ?? 'general',
                        'lat' => $row['lat'] ?? 0,
                        'lng' => $row['lng'] ?? 0,
                        'ticket_price' => $row['ticket_price'] ?? null,
                        'opening_hours' => $row['opening_hours'] ?? null,
                        'mobile_signal' => $row['mobile_signal'] ?? null,
                        'road_condition' => $row['road_condition'] ?? null,
                        'activities' => $row['activities'] ?? null,
                        'tourist_popularity' => $row['tourist_popularity'] ?? null,
                        'family_friendly' => $row['family_friendly'] ?? null,
                        'budget_category' => $row['budget_category'] ?? null,
                        'parking_avail' => $row['parking_avail'] ?? null,
                        'toilets' => $row['toilets'] ?? null,
                        'food_nearby' => $row['food_nearby'] ?? null,
                        'wheelchair_access' => $row['wheelchair_access'] ?? null,
                        'camping_allowed' => $row['camping_allowed'] ?? null,
                        'safety_level' => $row['safety_level'] ?? null,
                        'wildlife_hazard' => $row['wildlife_hazard'] ?? null,
                        'guide_required' => $row['guide_required'] ?? null,
                        'rain_sensitivity' => $row['rain_sensitivity'] ?? null,
                        'monsoon_note' => $row['monsoon_note'] ?? null,
                        'best_time_to_visit' => $row['best_time_to_visit'] ?? null,
                        'height_m' => $row['Height_m'] ?? null,
                        'length_km' => $row['Length_km'] ?? null,
                        'surfing' => $row['Surfing'] ?? null,
                        'status' => Place::STATUS_APPROVED,
                        'is_deleted' => false,
                    ]
                );
                $imported++;
            }
        }

        $this->command->info("Imported: {$imported}, Skipped: {$skipped}");
    }
}
