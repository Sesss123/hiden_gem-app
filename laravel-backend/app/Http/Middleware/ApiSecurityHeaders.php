<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class ApiSecurityHeaders
{
    /**
     * Handle an incoming request and attach enterprise security headers.
     *
     * @param  Request  $request
     * @param  \Closure(Request): (\Illuminate\Http\Response|\Illuminate\Http\RedirectResponse)  $next
     * @return \Illuminate\Http\Response|\Illuminate\Http\RedirectResponse
     */
    public function handle(Request $request, Closure $next)
    {
        $response = $next($request);

        if (method_exists($response, 'header')) {
            // Prevent browsers from MIME-sniffing a response away from the declared content-type
            $response->header('X-Content-Type-Options', 'nosniff');
            // Protect against Clickjacking attacks
            $response->header('X-Frame-Options', 'DENY');
            // Enable Cross-site scripting (XSS) filter in browsers
            $response->header('X-XSS-Protection', '1; mode=block');
            // Ensure communication over HTTPS
            $response->header('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');
            // Control referrer information sent with requests
            $response->header('Referrer-Policy', 'strict-origin-when-cross-origin');
        }

        return $response;
    }
}
