<?php

namespace App\Http\Resources\Concerns;

trait BuildsPublicStorageUrl
{
    /**
     * Builds a full public URL from a stored image path. ImageProcessingService
     * saves thumb_path/full_path already prefixed with "/storage/" (e.g.
     * "/storage/places/{id}/thumb/{uuid}.webp") — prepending asset('storage/...')
     * on top of that without stripping the existing prefix first doubles it
     * into ".../storage/storage/places/..." and 404s for every client. Strip
     * any leading "storage/" before re-adding it so this works whether the
     * stored path already has the prefix or not.
     */
    private function toPublicUrl(?string $path): ?string
    {
        if (!$path) {
            return $path;
        }
        if (str_starts_with($path, 'http')) {
            return $path;
        }
        $relative = ltrim($path, '/');
        if (str_starts_with($relative, 'storage/')) {
            $relative = substr($relative, strlen('storage/'));
        }
        return asset('storage/' . $relative);
    }
}
