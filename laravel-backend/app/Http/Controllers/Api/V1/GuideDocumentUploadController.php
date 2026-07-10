<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class GuideDocumentUploadController extends Controller
{
    /**
     * Upload a guide enrollment document (license, NIC, or selfie photo).
     * Stores under storage/app/public/guide_documents/{uid}/ and returns the
     * public URL — this is the self-hosted replacement for the Firebase
     * Storage upload path, so it can move to a VPS unchanged later.
     */
    public function upload(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'doc_type' => 'required|string|in:license,nic,selfie',
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
        $docType = $request->input('doc_type');
        $file = $request->file('file');

        $fileName = now()->timestamp . '_' . $docType . '.' . $file->getClientOriginalExtension();
        $path = $file->storeAs("guide_documents/{$uid}", $fileName, 'public');

        return response()->json([
            'status' => 'success',
            'message' => 'Document uploaded successfully.',
            'data' => [
                'url' => Storage::url($path),
                'full_url' => $request->getSchemeAndHttpHost() . Storage::url($path),
            ],
        ], 200);
    }
}
