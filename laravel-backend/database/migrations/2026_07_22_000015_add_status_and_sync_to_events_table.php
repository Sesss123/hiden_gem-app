<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Brings events up to the same approval/sync scaffolding places already has
 * (see 2026_07_02_000005_add_review_status_to_places_table.php and
 * 2026_07_22_000014_default_sync_version_on_places_table.php) — status
 * defaults to approved to match existing admin-created events staying live
 * immediately; sync_version defaults to 0 from the start (unlike places,
 * which only got a default added later) since EventObserver mirrors
 * PlaceObserver's approved-only bump from day one.
 */
return new class extends Migration
{
    public function up()
    {
        Schema::table('events', function (Blueprint $table) {
            $table->string('status', 20)->default('approved')->index()->after('created_by');
            $table->unsignedBigInteger('reviewed_by')->nullable()->after('status');
            $table->text('review_reason')->nullable()->after('reviewed_by');
            $table->boolean('is_deleted')->default(false)->index()->after('review_reason');
            $table->unsignedBigInteger('sync_version')->default(0)->index()->after('is_deleted');
        });

        Schema::table('events', function (Blueprint $table) {
            $table->foreign('reviewed_by')->references('id')->on('users')->nullOnDelete();
        });
    }

    public function down()
    {
        Schema::table('events', function (Blueprint $table) {
            $table->dropForeign(['reviewed_by']);
            $table->dropColumn(['status', 'reviewed_by', 'review_reason', 'is_deleted', 'sync_version']);
        });
    }
};
