<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * guide_applications.user_id was created as BIGINT with an FK to
     * users.id (undocumented — not in the original migration file), but the
     * model, comments, and every caller in this codebase treat it as the
     * Firebase UID string. GuideApplication::user() (belongsTo
     * users.firebase_uid) always resolved to null, crashing admin
     * approve/reject/ban/remove. Drop the wrong FK, widen the column, then
     * backfill existing rows from the bigint id to the real firebase_uid
     * while it's still numeric.
     */
    public function up(): void
    {
        Schema::table('guide_applications', function ($table) {
            $table->dropForeign('guide_applications_user_id_foreign');
        });

        DB::statement('ALTER TABLE guide_applications MODIFY user_id VARCHAR(128) NOT NULL');

        DB::table('guide_applications')->orderBy('id')->each(function ($application) {
            if (ctype_digit((string) $application->user_id)) {
                $user = DB::table('users')->where('id', $application->user_id)->first();
                if ($user && $user->firebase_uid) {
                    DB::table('guide_applications')
                        ->where('id', $application->id)
                        ->update(['user_id' => $user->firebase_uid]);
                }
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        DB::statement('ALTER TABLE guide_applications MODIFY user_id BIGINT UNSIGNED NOT NULL');
        Schema::table('guide_applications', function ($table) {
            $table->foreign('user_id')->references('id')->on('users');
        });
    }
};
