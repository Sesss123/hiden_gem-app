<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\GuideApplication;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;
use App\Services\FirestoreService;

class GuideApplicationController extends Controller
{
    /**
     * Submit or re-submit a guide application from the mobile app.
     */
    public function submit(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'nullable|email|max:255',
            'name' => 'nullable|string|max:255',
            'license_number' => 'required|string|max:255',
            'bio' => 'nullable|string',
            'category' => 'required|string|max:100',
            'license_doc_url' => ['nullable', 'string', 'max:500', 'url', 'regex:/^https?:\/\/(firebasestorage\.googleapis\.com\/v0\/b\/tripme-89742\.(firebasestorage\.app|appspot\.com)|cdn\.hiddengemssl\.com|[^\/]+\/storage\/guide_documents\/)/'],
            'nic_doc_url' => ['nullable', 'string', 'max:500', 'url', 'regex:/^https?:\/\/(firebasestorage\.googleapis\.com\/v0\/b\/tripme-89742\.(firebasestorage\.app|appspot\.com)|cdn\.hiddengemssl\.com|[^\/]+\/storage\/guide_documents\/)/'],
            'selfie_doc_url' => ['nullable', 'string', 'max:500', 'url', 'regex:/^https?:\/\/(firebasestorage\.googleapis\.com\/v0\/b\/tripme-89742\.(firebasestorage\.app|appspot\.com)|cdn\.hiddengemssl\.com|[^\/]+\/storage\/guide_documents\/)/'],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => 'Validation failed.',
                'errors' => $validator->errors(),
            ], 422);
        }

        $validated = $validator->validated();
        $validated['status'] = 'pending';
        $validated['applied_at'] = now();

        $application = GuideApplication::updateOrCreate(
            ['user_id' => (string) $request->user()->firebase_uid],
            $validated
        );

        return response()->json([
            'status' => 'success',
            'message' => 'Guide application submitted successfully for review.',
            'data' => $application,
        ], 200);
    }

    /**
     * Check application status for the authenticated user.
     * The {userId} route segment is not used for lookup — status is always
     * scoped to the authenticated Sanctum user to prevent IDOR.
     */
    public function myStatus(Request $request, string $userId)
    {
        $application = GuideApplication::where('user_id', (string) $request->user()->firebase_uid)->first();

        if (!$application) {
            return response()->json([
                'status' => 'success',
                'data' => null,
            ], 200);
        }

        return response()->json([
            'status' => 'success',
            'data' => $application,
        ], 200);
    }

    /**
     * Admin: Get all guide applications (optional filter by status).
     */
    public function index(Request $request)
    {
        $query = GuideApplication::query();

        if ($request->has('status')) {
            $query->where('status', $request->query('status'));
        }

        $applications = $query->orderBy('applied_at', 'desc')->get();

        return response()->json([
            'status' => 'success',
            'data' => $applications,
        ], 200);
    }

    /**
     * Admin: Approve a guide application.
     */
    public function approve(Request $request, $id)
    {
        $application = GuideApplication::where(function ($query) use ($id) {
            if (is_numeric($id)) {
                $query->where('id', $id);
            }
            $query->orWhere('user_id', $id);
        })->first();

        if (!$application) {
            return response()->json([
                'status' => 'error',
                'message' => 'Guide application not found.',
            ], 404);
        }

        DB::transaction(function () use ($application) {
            $application->update([
                'status' => 'approved',
                'reviewed_at' => now(),
                'admin_comment' => null,
            ]);

            // If a local user exists in MySQL, update their role
            $user = User::where('email', $application->email)->orWhere('id', $application->user_id)->first();
            if ($user) {
                $user->update(['role' => 'guide_approved']);
            }
        });

        // Sync to Firestore — guide_applications & users collections
        dispatch(function () use ($application) {
            try {
                $firestoreService = new FirestoreService();
                $firestoreService->updateGuideApplication($application->user_id, [
                    'status' => 'approved',
                    'reviewedAt' => now()->toIso8601String(),
                ]);
                $firestoreService->updateGuideUser($application->user_id, [
                    'role' => 'guide_approved',
                    'guideStatus' => 'approved',
                    'isGuideApproved' => true,
                ]);
            } catch (\Exception $e) {
                Log::error("Firestore sync failed in API approve (queued): " . $e->getMessage());
            }
        });

        return response()->json([
            'status' => 'success',
            'message' => 'Guide application approved successfully.',
            'data' => $application,
        ], 200);
    }

    /**
     * Admin: Reject a guide application with a reason.
     */
    public function reject(Request $request, $id)
    {
        $validator = Validator::make($request->all(), [
            'admin_comment' => 'required|string|max:1000',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => 'Rejection reason (admin_comment) is required.',
                'errors' => $validator->errors(),
            ], 422);
        }

        $application = GuideApplication::where(function ($query) use ($id) {
            if (is_numeric($id)) {
                $query->where('id', $id);
            }
            $query->orWhere('user_id', $id);
        })->first();

        if (!$application) {
            return response()->json([
                'status' => 'error',
                'message' => 'Guide application not found.',
            ], 404);
        }

        $application->update([
            'status' => 'rejected',
            'reviewed_at' => now(),
            'admin_comment' => $request->input('admin_comment'),
        ]);

        $adminComment = $request->input('admin_comment');

        // Sync to Firestore — guide_applications & users collections
        dispatch(function () use ($application, $adminComment) {
            try {
                $firestoreService = new FirestoreService();
                $firestoreService->updateGuideApplication($application->user_id, [
                    'status' => 'rejected',
                    'adminComment' => $adminComment,
                    'reviewedAt' => now()->toIso8601String(),
                ]);
                $firestoreService->updateGuideUser($application->user_id, [
                    'guideStatus' => 'rejected',
                    'guideRejectionReason' => $adminComment,
                ]);
            } catch (\Exception $e) {
                Log::error("Firestore sync failed in API reject (queued): " . $e->getMessage());
            }
        });

        return response()->json([
            'status' => 'success',
            'message' => 'Guide application rejected.',
            'data' => $application,
        ], 200);
    }
}
