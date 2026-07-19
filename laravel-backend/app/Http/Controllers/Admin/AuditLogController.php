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
        return view('admin.audit-log.index', compact('logs'));
    }
}
