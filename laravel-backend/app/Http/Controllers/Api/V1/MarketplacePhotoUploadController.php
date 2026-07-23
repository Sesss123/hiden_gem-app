<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\ImageProcessingService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class MarketplacePhotoUploadController extends Controller
{
    protected $imageService;

    public function __construct(ImageProcessingService $imageService)
    {
        $this->imageService = $imageService;
    }

    /**
     * Upload a guide listing photo (cover photo or vehicle photo).
     * Stores under storage/app/public/listing_photos/{uid}/ — routed through
     * ImageProcessingService (the same dual-tier WebP thumb/hero pipeline
     * Places/Events use) instead of storing the raw upload as-is, since these
     * are public marketplace-facing photos served in the discovery grid.
     */
    public function upload(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'photo_type' => 'required|string|max:100',
            'file' => 'required|file|image|max:10240', // 10MB
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => 'Validation failed.',
                'errors' => $validator->errors(),
            ], 422);
        }

        $uid = (string) $request->user()->firebase_uid ?: (string) $request->user()->id;
        $photoType = preg_replace('/[^A-Za-z0-9_\-]/', '', $request->input('photo_type'));
        $file = $request->file('file');

        $paths = $this->imageService->processAndStore($file, "{$uid}/{$photoType}", 'listing_photos');

        return response()->json([
            'status' => 'success',
            'message' => 'Photo uploaded successfully.',
            'data' => [
                'url' => $paths['full_path'],
                'full_url' => $request->getSchemeAndHttpHost() . $paths['full_path'],
                'thumb_url' => $request->getSchemeAndHttpHost() . $paths['thumb_path'],
            ],
        ], 200);
    }
}
