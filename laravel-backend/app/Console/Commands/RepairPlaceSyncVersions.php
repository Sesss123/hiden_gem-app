<?php

namespace App\Console\Commands;

use App\Models\Place;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class RepairPlaceSyncVersions extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'places:repair-sync {--all : Force bump sync_version for all places} {--id= : Repair sync_version for a specific place ID}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Repair and bump sync_version for places modified outside Eloquent or missing version tracking';

    /**
     * Execute the console command.
     *
     * @return int
     */
    public function handle()
    {
        $this->info('Scanning for places needing sync_version repair...');

        $query = Place::query();

        if ($this->option('id')) {
            $query->where('id', $this->option('id'));
        } elseif (!$this->option('all')) {
            // Target rows where sync_version is 0, null, or where updated_at is newer than expected
            // If --all is not passed, we default to fixing rows with sync_version == 0 or null
            $query->where(function ($q) {
                $q->whereNull('sync_version')->orWhere('sync_version', '<=', 0);
            });
        }

        $places = $query->get();
        $count = $places->count();

        if ($count === 0) {
            $this->info('No places found needing sync_version repair. Use --all to force bump all places.');
            return 0;
        }

        $this->info("Found {$count} place(s) to repair. Bumping sync_version...");

        $repaired = 0;

        foreach ($places as $place) {
            DB::beginTransaction();
            try {
                // Lock sequence row and increment global sync_version
                $counter = DB::table('sync_counter')->where('id', 1)->lockForUpdate()->first();
                $newVersion = ($counter ? $counter->current_version : 0) + 1;
                DB::table('sync_counter')->where('id', 1)->update(['current_version' => $newVersion]);

                // Update place sync_version directly so mobile clients pull this row
                DB::table('places')->where('id', $place->id)->update([
                    'sync_version' => $newVersion,
                    'updated_at' => now(),
                ]);

                DB::commit();
                $repaired++;
            } catch (\Exception $e) {
                DB::rollBack();
                $this->error("Failed to repair place {$place->id}: " . $e->getMessage());
            }
        }

        $this->info("Successfully repaired and bumped sync_version for {$repaired} place(s)!");
        return 0;
    }
}
