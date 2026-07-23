<?php

namespace App\Http\Middleware;

/**
 * Registered as the 'is_admin' Kernel alias, used on the API-side
 * admin/guide-applications and admin/guide-listings route groups. Checking
 * is_admin alone is not enough — the restricted content_manager role also
 * has is_admin=true (so it can reach the web admin panel at all), but must
 * not reach these API routes (guide/listing approval etc.), which are
 * full-admin-only actions — so this enforces exactly the same check as
 * IsFullAdmin ('full_admin' alias, used in routes/web.php). Extends it
 * (inheriting handle() as-is) rather than duplicating the check, so the two
 * aliases can never silently drift apart if one is ever edited without the
 * other.
 */
class IsAdmin extends IsFullAdmin
{
}
