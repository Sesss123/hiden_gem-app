<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class MarketplacePhotoUploadController extends Controller
{
    /**
     * Upload a guide listing photo (cover photo or vehicle photo).
     * Stores under storage/app/public/listing_photos/{uid}/ and returns the
     * public URL — self-hosted replacement for the Firebase Storage path.
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

        $fileName = now()->timestamp . '_' . $photoType . '.' . $file->getClientOriginalExtension();
        $path = $file->storeAs("listing_photos/{$uid}", $fileName, 'public');

        return response()->json([
            'status' => 'success',
            'message' => 'Photo uploaded successfully.',
            'data' => [
                'url' => Storage::url($path),
                'full_url' => $request->getSchemeAndHttpHost() . Storage::url($path),
            ],
        ], 200);
    }
}
