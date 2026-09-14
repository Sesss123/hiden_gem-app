<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class RequireRecentAdminLogin
{
    public function handle(Request $request, Closure $next, int $minutes = 10)
    {
        $authenticatedAt = (int) $request->session()->get('admin_authenticated_at', 0);

        if ($authenticatedAt > 0 && (time() - $authenticatedAt) <= ($minutes * 60)) {
            return $next($request);
        }

        // Never store the mutating POST/DELETE URL as Laravel's post-login
        // GET destination; that would cause a 405 and could tempt unsafe
        // automatic replay. Return the admin to the form/list instead.
        $previous = url()->previous();
        $intended = parse_url($previous, PHP_URL_HOST) === $request->getHost()
            ? $previous
            : route('admin.places.index');
        Auth::logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();
        $request->session()->put('url.intended', $intended);

        return redirect()->route('admin.login')
            ->withErrors(['email' => 'Please sign in again to authorize this sensitive action.']);
    }
}
