<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\AdminAuditLog;
use Illuminate\Http\Request;

class AuditLogController extends Controller
{
    public function index(Request $request)
    {
        $query = AdminAuditLog::with('user')->orderBy('created_at', 'desc');

        if ($action = $request->input('action')) {
            $query->where('action', 'like', "%{$action}%");
        }

        if ($actor = $request->input('actor')) {
            $query->where(function ($q) use ($actor) {
                $q->where('actor_name', 'like', "%{$actor}%")
                  ->orWhere('actor_email', 'like', "%{$actor}%");
            });
        }

        $logs = $query->paginate(25);
        $totalLogs = AdminAuditLog::count();
        return view('admin.audit-log.index', compact('logs', 'totalLogs'));
    }

    /**
     * Delete an individual audit log entry.
     */
    public function destroy($id)
    {
        abort(403, 'Audit records are append-only and cannot be deleted from the admin panel.');
        if (!auth()->user()->isFullAdmin()) {
            abort(403, 'Unauthorized action. Only administrators can delete audit logs.');
        }

        $log = AdminAuditLog::findOrFail($id);
        $log->delete();

        return redirect()->back()->with('success', 'Audit log entry removed successfully.');
    }

    /**
     * Bulk clean old audit logs based on timeframe.
     */
    public function clear(Request $request)
    {
        abort(403, 'Audit records are append-only and cannot be cleared from the admin panel.');
        if (!auth()->user()->isFullAdmin()) {
            abort(403, 'Unauthorized action. Only administrators can clear audit logs.');
        }

        $timeframe = $request->input('timeframe', '30_days');
        $query = AdminAuditLog::query();

        if ($timeframe === '7_days') {
            $deleted = $query->where('created_at', '<', now()->subDays(7))->delete();
            $msg = "Logs older than 7 days removed ({$deleted} records).";
        } elseif ($timeframe === '30_days') {
            $deleted = $query->where('created_at', '<', now()->subDays(30))->delete();
            $msg = "Logs older than 30 days removed ({$deleted} records).";
        } elseif ($timeframe === '60_days') {
            $deleted = $query->where('created_at', '<', now()->subDays(60))->delete();
            $msg = "Logs older than 60 days removed ({$deleted} records).";
        } elseif ($timeframe === '90_days') {
            $deleted = $query->where('created_at', '<', now()->subDays(90))->delete();
            $msg = "Logs older than 90 days removed ({$deleted} records).";
        } elseif ($timeframe === 'all') {
            $deleted = $query->delete();
            $msg = "All audit logs have been successfully cleared ({$deleted} records).";
        } else {
            return redirect()->back()->with('error', 'Invalid timeframe specified.');
        }

        return redirect()->back()->with('success', $msg);
    }
}
