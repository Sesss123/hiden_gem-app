<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class IsFullAdmin
{
    /**
     * Handle an incoming request.
     * Ensure the authenticated user has full admin privileges (not a restricted
     * content_manager role, which is limited to Places/Events via a separate group).
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \Closure  $next
     * @return mixed
     */
    public function handle(Request $request, Closure $next)
    {
        if (!Auth::check() || !Auth::user()->is_admin || !Auth::user()->isFullAdmin()) {
            abort(403, 'Unauthorized access. Full admin privileges required.');
        }

        return $next($request);
    }
}
