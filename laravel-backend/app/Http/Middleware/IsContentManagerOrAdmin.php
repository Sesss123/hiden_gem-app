<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class IsContentManagerOrAdmin
{
    /**
     * Handle an incoming request.
     * Allows both full admins and the restricted content_manager role through —
     * used for the shared Places/Events routes both roles can reach.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \Closure  $next
     * @return mixed
     */
    public function handle(Request $request, Closure $next)
    {
        if (!Auth::check() || !Auth::user()->is_admin) {
            abort(403, 'Unauthorized access. Admin privileges required.');
        }

        $user = Auth::user();
        if (!$user->isFullAdmin() && !$user->isContentManager()) {
            abort(403, 'Your role does not have access to this area.');
        }

        return $next($request);
    }
}
