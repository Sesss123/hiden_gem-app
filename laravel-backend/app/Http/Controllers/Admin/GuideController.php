<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\GuideApplication;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class GuideController extends Controller
{
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
        return view('admin.guides.show', compact('application'));
    }

    public function approve($id)
    {
        $application = GuideApplication::findOrFail($id);
        
        DB::transaction(function () use ($application) {
            $application->update(['status' => 'approved']);

            $user = $application->user;
            $user->update(['role' => 'guide_approved']);
        });

        return redirect()->route('admin.guides.index', ['status' => 'approved'])
            ->with('success', "Guide application for '{$application->user->name}' has been approved. User role elevated to 'guide_approved'.");
    }

    public function reject(Request $request, $id)
    {
        $application = GuideApplication::findOrFail($id);
        
        DB::transaction(function () use ($application) {
            $application->update(['status' => 'rejected']);

            $user = $application->user;
            $user->update(['role' => 'tourist']); // demote back to tourist
        });

        return redirect()->route('admin.guides.index', ['status' => 'rejected'])
            ->with('success', "Guide application for '{$application->user->name}' has been rejected.");
    }

    public function ban($id)
    {
        $application = GuideApplication::findOrFail($id);
        $user = $application->user;
        $user->update(['role' => 'banned']);

        return back()->with('success', "User '{$user->name}' has been permanently banned.");
    }

    public function remove($id)
    {
        $application = GuideApplication::findOrFail($id);
        $user = $application->user;
        $user->update(['role' => 'tourist']);
        
        $application->delete();

        return redirect()->route('admin.guides.index')
            ->with('success', "Guide association for '{$user->name}' has been removed.");
    }
}
