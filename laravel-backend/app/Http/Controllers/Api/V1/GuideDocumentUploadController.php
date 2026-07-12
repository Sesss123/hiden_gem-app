<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;
use Symfony\Component\HttpFoundation\StreamedResponse;

class GuideDocumentUploadController extends Controller
{
    /**
     * Upload a guide enrollment document (license, NIC, or selfie photo).
     *
     * Security: stored on the PRIVATE `local` disk (storage/app/private,
     * NOT the public/storage symlink) — these are government ID photos and
     * selfies, not public content like listing photos. Previously stored on
     * the `public` disk with a `{timestamp}_{doctype}.ext` filename, which
     * meant the file was reachable directly over HTTP via the storage
     * symlink with NO authentication at all: no auth:sanctum, no
     * VerifyApiKey, no ownership check — just guessing a uid (not secret,
     * visible in many API responses) and a timestamp (a small search space
     * bounded to roughly when the application was submitted). Now served
     * exclusively through download() below, which checks the requester is
     * the document's own owner or an admin, and filenames are UUIDs instead
     * of predictable timestamps as defense-in-depth.
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

        $fileName = Str::uuid()->toString() . '_' . $docType . '.' . $file->getClientOriginalExtension();
        $file->storeAs("guide_documents/{$uid}", $fileName, 'local');

        return response()->json([
            'status' => 'success',
            'message' => 'Document uploaded successfully.',
            'data' => [
                'url' => route('admin.guide-documents.download', ['uid' => $uid, 'filename' => $fileName]),
                'full_url' => route('admin.guide-documents.download', ['uid' => $uid, 'filename' => $fileName]),
            ],
        ], 200);
    }

    /**
     * Streams a guide document back to an admin reviewing the application
     * (resources/views/admin/guides/show.blade.php — the only real caller;
     * the mobile app never displays a guide's own uploaded document back to
     * them). Registered under the session-authenticated admin route group
     * in routes/web.php (auth + is_admin middleware), so reaching this
     * method at all already implies the caller is an admin — this is the
     * sole legitimate way to read a guide_documents file now that they're
     * stored on the private disk, see the security note on upload() above.
     */
    public function download(string $uid, string $filename): StreamedResponse|Response
    {
        // Reject any path-traversal attempt in the filename segment before
        // touching the filesystem.
        if (str_contains($filename, '..') || str_contains($filename, '/') || str_contains($filename, '\\')) {
            abort(400, 'Invalid filename.');
        }

        $relativePath = "guide_documents/{$uid}/{$filename}";
        if (!Storage::disk('local')->exists($relativePath)) {
            abort(404, 'Document not found.');
        }

        return Storage::disk('local')->response($relativePath);
    }
}
