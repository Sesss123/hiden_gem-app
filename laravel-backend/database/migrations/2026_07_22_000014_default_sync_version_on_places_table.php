<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * PlaceObserver now only assigns sync_version once a place is approved (see
 * app/Observers/PlaceObserver.php) — a pending submission never reaches the
 * mobile app's delta sync, so it shouldn't consume a version number. That
 * means INSERT no longer always supplies sync_version, so the column needs
 * a default instead of relying on the observer to fill it every time.
 * 0 is safe: delta()'s since_version>0 branch filters by sync_version > cursor
 * (0 never matches), and its since_version=0 branch filters by status=approved
 * separately — a pending place with sync_version=0 is invisible either way.
 *
 * Uses raw SQL (not Schema::table()->change()) to avoid adding doctrine/dbal
 * as a direct dependency just for this one column-default change.
 */
return new class extends Migration
{
    public function up(): void
    {
        DB::statement('ALTER TABLE places MODIFY sync_version BIGINT UNSIGNED NOT NULL DEFAULT 0');
    }

    public function down(): void
    {
        DB::statement('ALTER TABLE places MODIFY sync_version BIGINT UNSIGNED NOT NULL');
    }
};
