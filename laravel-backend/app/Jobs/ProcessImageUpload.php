<?php

namespace App\Jobs;

use App\Models\EventImage;
use App\Models\PlaceImage;
use App\Services\ImageProcessingService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;

/**
 * Resizes/WebP-encodes an uploaded image and fills in the real thumb_path/
 * full_path on an already-created PlaceImage or EventImage row — moved off
 * the request/response cycle (and out of the create-row DB transaction) so a
 * batch of large photo uploads no longer holds a place/event row's
 * transaction open for the length of the CPU-bound GD pipeline.
 *
 * The controller does the synchronous part first (copy the upload's raw
 * bytes to a stable holding path, create the row with status=processing and
 * the shared placeholder image), then dispatches this job with just that
 * holding path — UploadedFile itself can't survive serialization onto the
 * queue, since it wraps a request-scoped temp file.
 */
class ProcessImageUpload implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public int $timeout = 60;

    public function __construct(
        private readonly string $ownerType,   // 'place' | 'event'
        private readonly int $imageId,        // PlaceImage/EventImage row id
        private readonly string $holdingPath, // path on the 'local' disk holding the raw upload
        private readonly string $ownerId,     // place_id / event_id, used in the storage path
        private readonly string $folder,      // 'places' | 'events'
        private readonly string $originalExtension,
    ) {
    }

    public function handle(ImageProcessingService $imageService): void
    {
        $model = $this->ownerType === 'event' ? EventImage::find($this->imageId) : PlaceImage::find($this->imageId);

        // The row (or its parent) may have been deleted while this job sat
        // in the queue — nothing to do, and nothing to fail loudly about.
        if (!$model) {
            $this->cleanupHoldingFile();
            return;
        }

        try {
            $sourcePath = Storage::disk('local')->path($this->holdingPath);
            $paths = $imageService->processFromPath($sourcePath, $this->ownerId, $this->folder, $this->originalExtension);

            $model->update([
                'thumb_path' => $paths['thumb_path'],
                'full_path' => $paths['full_path'],
                'status' => 'ready',
            ]);
        } catch (\Throwable $e) {
            Log::error('ProcessImageUpload failed', [
                'owner_type' => $this->ownerType,
                'image_id' => $this->imageId,
                'error' => $e->getMessage(),
            ]);
            $model->update(['status' => 'failed']);
        } finally {
            $this->cleanupHoldingFile();
        }
    }

    private function cleanupHoldingFile(): void
    {
        Storage::disk('local')->delete($this->holdingPath);
    }
}
