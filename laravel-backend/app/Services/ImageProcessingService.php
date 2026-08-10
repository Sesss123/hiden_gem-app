<?php

namespace App\Services;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class ImageProcessingService
{
    /**
     * Processes an uploaded image file, generating a 400px WebP thumbnail
     * and a 1080px WebP hero version, saving both to public storage under
     * "{$folder}/{$ownerId}/...". $folder lets callers other than Places
     * (e.g. Events) store into their own tree instead of being nested under
     * "places/" — pass 'places' from PlaceController to keep existing paths
     * unchanged.
     *
     * @param UploadedFile $file
     * @param string $ownerId
     * @param string $folder
     * @return array {thumb_path: string, full_path: string}
     */
    public function processAndStore(UploadedFile $file, string $ownerId, string $folder = 'places'): array
    {
        return $this->processFromPath($file->getRealPath(), $ownerId, $folder, $file->getClientOriginalExtension());
    }

    /**
     * Same pipeline as processAndStore(), but reads from an already-saved
     * disk path instead of a live UploadedFile — used by ProcessImageUpload
     * (queued), since UploadedFile wraps a request-scoped temp file that's
     * gone by the time a queue worker picks the job up.
     *
     * @param string $sourcePath Absolute path to the raw image bytes.
     * @param string $ownerId
     * @param string $folder
     * @param string $originalExtension Used only by the no-GD fallback path.
     * @return array {thumb_path: string, full_path: string}
     */
    public function processFromPath(string $sourcePath, string $ownerId, string $folder, string $originalExtension = 'jpg'): array
    {
        $filename = Str::uuid()->toString();
        $thumbRelPath = "{$folder}/{$ownerId}/thumb/{$filename}.webp";
        $fullRelPath = "{$folder}/{$ownerId}/full/{$filename}.webp";

        // Create storage directories if they don't exist
        Storage::disk('public')->makeDirectory("{$folder}/{$ownerId}/thumb");
        Storage::disk('public')->makeDirectory("{$folder}/{$ownerId}/full");

        // Check if GD extension is available for WebP conversion
        if (function_exists('imagecreatefromstring') && function_exists('imagewebp')) {
            $imageData = file_get_contents($sourcePath);
            $sourceImage = @imagecreatefromstring($imageData);

            if ($sourceImage === false) {
                // BUG-L001: Do NOT fall through to arbitrary file storage if GD fails to parse image!
                throw new \InvalidArgumentException("Uploaded file could not be parsed as a valid image by GD graphics engine.");
            }

            $width = imagesx($sourceImage);
            $height = imagesy($sourceImage);

            if ($width <= 0 || $height <= 0) {
                throw new \InvalidArgumentException("Uploaded image has invalid dimensions.");
            }

            // 1. Generate 1080px Hero WebP (if wider than 1080)
            $fullWidth = min($width, 1080);
            $fullHeight = (int) ($height * ($fullWidth / $width));
            $fullImg = imagecreatetruecolor($fullWidth, $fullHeight);
            imagealphablending($fullImg, false);
            imagesavealpha($fullImg, true);
            imagecopyresampled($fullImg, $sourceImage, 0, 0, 0, 0, $fullWidth, $fullHeight, $width, $height);

            $fullTempPath = sys_get_temp_dir() . "/full_{$filename}.webp";
            imagewebp($fullImg, $fullTempPath, 85);
            Storage::disk('public')->put($fullRelPath, file_get_contents($fullTempPath));
            @unlink($fullTempPath);
            imagedestroy($fullImg);

            // 2. Generate 400px Thumb WebP (if wider than 400)
            $thumbWidth = min($width, 400);
            $thumbHeight = (int) ($height * ($thumbWidth / $width));
            $thumbImg = imagecreatetruecolor($thumbWidth, $thumbHeight);
            imagealphablending($thumbImg, false);
            imagesavealpha($thumbImg, true);
            imagecopyresampled($thumbImg, $sourceImage, 0, 0, 0, 0, $thumbWidth, $thumbHeight, $width, $height);

            $thumbTempPath = sys_get_temp_dir() . "/thumb_{$filename}.webp";
            imagewebp($thumbImg, $thumbTempPath, 80);
            Storage::disk('public')->put($thumbRelPath, file_get_contents($thumbTempPath));
            @unlink($thumbTempPath);
            imagedestroy($thumbImg);
            imagedestroy($sourceImage);

            return [
                'thumb_path' => "/storage/" . $thumbRelPath,
                'full_path' => "/storage/" . $fullRelPath,
            ];
        }

        // BUG-L001: Fallback direct storage MUST validate extension to prevent webshell/RCE uploads
        $allowedExts = ['jpg', 'jpeg', 'png', 'webp'];
        $ext = strtolower($originalExtension ?: 'jpg');
        if (!in_array($ext, $allowedExts)) {
            throw new \InvalidArgumentException("Invalid image extension: .{$ext}. Only JPG, PNG, and WebP are allowed.");
        }

        $fallbackThumb = "{$folder}/{$ownerId}/thumb/{$filename}.{$ext}";
        $fallbackFull = "{$folder}/{$ownerId}/full/{$filename}.{$ext}";
        Storage::disk('public')->put("{$folder}/{$ownerId}/thumb/{$filename}.{$ext}", file_get_contents($sourcePath));
        Storage::disk('public')->put("{$folder}/{$ownerId}/full/{$filename}.{$ext}", file_get_contents($sourcePath));

        return [
            'thumb_path' => "/storage/" . $fallbackThumb,
            'full_path' => "/storage/" . $fallbackFull,
        ];
    }
}
