<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\GuideApplication;
use App\Models\User;
use App\Services\FirestoreService;
use App\Traits\LogsAdminActivity;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class GuideController extends Controller
{
    use LogsAdminActivity;

    private FirestoreService $firestoreService;

    /**
     * Initialize controller with Firestore wrapper service.
     */
    public function __construct()
    {
        $this->firestoreService = new FirestoreService();
    }

    public function index(Request $request)
    {
        $status = $request->input('status', 'pending');
        $query = GuideApplication::with('user')->where('status', $status);

        if ($search = $request->input('search')) {
            // BUG-L003: Wrap search condition in an explicit grouping closure so orWhere doesn't bypass status filter
            $query->where(function ($q) use ($search) {
                $q->whereHas('user', function ($uq) use ($search) {
                    $uq->where('name', 'like', "%{$search}%")
                       ->orWhere('email', 'like', "%{$search}%");
                })->orWhere('license_number', 'like', "%{$search}%");
            });
        }

        $applications = $query->orderBy('created_at', 'desc')->paginate(15);
        $pendingCount = GuideApplication::where('status', 'pending')->count();
        $approvedCount = GuideApplication::where('status', 'approved')->count();
        $rejectedCount = GuideApplication::where('status', 'rejected')->count();

        return view('admin.guides.index', compact('applications', 'status', 'pendingCount', 'approvedCount', 'rejectedCount'));
    }

    public function show($id)
    {
        $application = GuideApplication::with('user')->findOrFail($id);

        $listing = null;
        $firebaseUid = $application->user->firebase_uid ?? null;
        if ($firebaseUid) {
            $listing = $this->firestoreService->getDocument('guide_listings', $firebaseUid);
        }

        return view('admin.guides.show', compact('application', 'listing'));
    }

    /**
     * Approve a guide application.
     * Synchronously updates MySQL and Google Cloud Firestore so the Flutter app
     * receives the status update in real time via watchMyApplication stream.
     */
    public function approve($id)
    {
        $application = GuideApplication::findOrFail($id);
        $userId = $application->user_id;
        
        try {
            DB::transaction(function () use ($application, $userId) {
                // 1. Update MySQL database (single source of truth for admin panel)
                $application->update(['status' => 'approved']);
                $application->user->update(['role' => 'guide_approved']);

                // 2. Sync to Firestore — guide_applications collection
                // This triggers watchMyApplication stream in Flutter's guide_enrollment_screen.dart
                $this->firestoreService->updateGuideApplication($userId, [
                    'status' => 'approved',
                    'reviewedAt' => now()->toIso8601String(),
                ]);

                // 3. Sync to Firestore — users collection
                // This updates profile role directly so dashboard tiles unlock immediately without restart
                $this->firestoreService->updateGuideUser($userId, [
                    'role' => 'guide_approved',
                    'guideStatus' => 'approved',
                    'isGuideApproved' => true,
                ]);
            });

            $this->logAdminAction('guide.approved', 'GuideApplication', $id, ['user_id' => $userId]);

            return redirect()->route('admin.guides.index', ['status' => 'approved'])
                ->with('success', "✅ Approved '{$application->user->name}'. Firestore synced — guide will see status update in app instantly.");

        } catch (\Exception $e) {
            Log::error("Approval sync failed for guide {$id}: " . $e->getMessage());
            return back()->with('error', "Approval failed (Firestore sync error). Check logs.");
        }
    }

    /**
     * Reject a guide application with an admin comment/reason.
     * Synchronously updates MySQL and Firestore so the guide can view the reason
     * and reapply immediately in the Flutter app.
     */
    public function reject(Request $request, $id)
    {
        $application = GuideApplication::findOrFail($id);
        $userId = $application->user_id;
        $adminComment = $request->input('admin_comment', 'Application does not meet requirements.');

        try {
            DB::transaction(function () use ($application, $userId, $adminComment) {
                // 1. Update MySQL database
                $application->update([
                    'status' => 'rejected',
                    'admin_comment' => $adminComment,
                ]);
                $application->user->update(['role' => 'tourist']); // demote back to tourist

                // 2. Sync to Firestore — guide_applications collection (includes rejection reason)
                $this->firestoreService->updateGuideApplication($userId, [
                    'status' => 'rejected',
                    'adminComment' => $adminComment,
                    'reviewedAt' => now()->toIso8601String(),
                ]);

                // 3. Sync to Firestore — users collection
                $this->firestoreService->updateGuideUser($userId, [
                    'guideStatus' => 'rejected',
                    'guideRejectionReason' => $adminComment,
                ]);
            });

            $this->logAdminAction('guide.rejected', 'GuideApplication', $id, ['user_id' => $userId, 'reason' => $adminComment]);

            return redirect()->route('admin.guides.index', ['status' => 'rejected'])
                ->with('success', "❌ Rejected '{$application->user->name}'. Reason sent to app — guide can reapply.");

        } catch (\Exception $e) {
            Log::error("Rejection sync failed for guide {$id}: " . $e->getMessage());
            return back()->with('error', "Rejection failed (Firestore sync error). Check logs.");
        }
    }

    /**
     * Permanently ban a guide/user.
     */
    public function ban($id)
    {
        $application = GuideApplication::findOrFail($id);
        $user = $application->user;
        $user->update(['role' => 'banned']);

        try {
            // NOTE: must use $application->user_id (the Firebase UID) here,
            // not $user->id (MySQL auto-increment PK) — every Firestore
            // users/{uid} doc is keyed by the Firebase UID, same as
            // approve()/reject() above already do correctly.
            $this->firestoreService->updateGuideUser($application->user_id, [
                'role' => 'banned',
                'guideStatus' => 'banned'
            ]);
        } catch (\Exception $e) {
            Log::warning("Firestore sync for ban failed: " . $e->getMessage());
        }

        $this->logAdminAction('guide.banned', 'User', $user->id, ['application_id' => $id]);

        return back()->with('success', "User '{$user->name}' has been permanently banned.");
    }

    /**
     * Remove guide association and delete application.
     */
    public function remove($id)
    {
        $application = GuideApplication::findOrFail($id);
        $user = $application->user;
        $user->update(['role' => 'tourist']);

        try {
            // NOTE: must use $application->user_id (the Firebase UID), not
            // $user->id (MySQL PK) — see comment in ban() above.
            $this->firestoreService->updateGuideUser($application->user_id, [
                'role' => 'tourist',
                'guideStatus' => 'removed',
                'isGuideApproved' => false
            ]);
            $this->firestoreService->updateGuideApplication($application->user_id, [
                'status' => 'removed'
            ]);
        } catch (\Exception $e) {
            Log::warning("Firestore sync for remove failed: " . $e->getMessage());
        }

        $application->delete();

        $this->logAdminAction('guide.removed', 'GuideApplication', $id, ['user_id' => $user->id]);

        return redirect()->route('admin.guides.index')
            ->with('success', "Guide association for '{$user->name}' has been removed.");
    }
}
