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
            // Content-Security-Policy — shared between api (inert on JSON) and web
            // (admin panel HTML). Allowlists exactly the CDN hosts the admin layout
            // loads (Tailwind, Font Awesome/cdnjs, Google Fonts, jsdelivr for Chart.js),
            // plus 'unsafe-inline' for the layout's existing inline config/style blocks.
            $response->header('Content-Security-Policy', implode('; ', [
                "default-src 'self'",
                // 'unsafe-eval' is required by cdn.tailwindcss.com's browser-side JIT
                // compiler (it uses eval()/new Function() to compile utility classes
                // at runtime) — without it the CDN build silently fails to apply any
                // styling under a strict CSP.
                "script-src 'self' 'unsafe-inline' 'unsafe-eval' https://cdn.tailwindcss.com https://cdnjs.cloudflare.com https://cdn.jsdelivr.net",
                "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com https://cdnjs.cloudflare.com",
                "font-src 'self' https://fonts.googleapis.com https://fonts.gstatic.com https://cdnjs.cloudflare.com",
                "img-src 'self' data: https:",
                "connect-src 'self'",
                "frame-ancestors 'none'",
                "base-uri 'self'",
                "form-action 'self'",
            ]));
        }

        return $response;
    }
}
