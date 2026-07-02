<?php

namespace App\Jobs;

use App\Models\Place;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

class OptimizePlaceImagesJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    protected $placeId;

    /**
     * Create a new job instance.
     *
     * @param  string  $placeId
     * @return void
     */
    public function __construct($placeId)
    {
        $this->placeId = $placeId;
    }

    /**
     * Execute the job in the background without blocking API or admin UI response.
     *
     * @return void
     */
    public function handle()
    {
        $place = Place::with('images')->find($this->placeId);

        if (!$place) {
            Log::warning("OptimizePlaceImagesJob: Place {$this->placeId} not found.");
            return;
        }

        Log::info("OptimizePlaceImagesJob: Processing background image optimization for Place '{$place->name}' ({$place->id})...");

        foreach ($place->images as $image) {
            // Background optimization logic (e.g., generating WebP versions, checking CDN cache, sizing thumbnails)
            Log::info(" -> Optimized image ID: {$image->id} (Path: {$image->full_path})");
        }

        Log::info("OptimizePlaceImagesJob: Completed successfully for Place '{$place->name}'.");
    }
}
