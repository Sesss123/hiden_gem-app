<?php

namespace App\Traits;

use App\Models\AdminAuditLog;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Request as RequestFacade;

trait LogsAdminActivity
{
    /**
     * Record an admin-panel mutating action. Deliberately called only at
     * points that change state (approve/reject/delete/ban/create/update) —
     * index/show reads are not logged, that would be noise, not signal.
     */
    protected function logAdminAction(string $action, ?string $targetType = null, $targetId = null, array $details = []): void
    {
        $user = Auth::user();

        AdminAuditLog::create([
            'user_id' => $user?->id,
            'actor_name' => $user?->name,
            'actor_email' => $user?->email,
            'action' => $action,
            'target_type' => $targetType,
            'target_id' => $targetId !== null ? (string) $targetId : null,
            'details' => $details,
            'ip_address' => RequestFacade::ip(),
            'created_at' => now(),
        ]);
    }
}
