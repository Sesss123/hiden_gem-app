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
        // The FK this drops was never created by a tracked migration — it
        // only existed on some environments from an undocumented out-of-band
        // change. Guard with an information_schema check so this migration
        // is reproducible on both a fresh DB (FK never existed) and any
        // live DB carrying the old undocumented FK.
        if ($this->foreignKeyExists('guide_applications', 'guide_applications_user_id_foreign')) {
            Schema::table('guide_applications', function ($table) {
                $table->dropForeign('guide_applications_user_id_foreign');
            });
        }

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
     *
     * Not a full reversal: once up() has backfilled user_id with Firebase UID
     * strings, those values can't cast back to BIGINT, so re-widening the
     * column to a numeric FK target would fail on any row already migrated.
     * This only restores the column type/FK shape for a database where up()
     * never actually ran any backfill (e.g. rolling back immediately).
     */
    public function down(): void
    {
        DB::statement('ALTER TABLE guide_applications MODIFY user_id BIGINT UNSIGNED NOT NULL');

        if (!$this->foreignKeyExists('guide_applications', 'guide_applications_user_id_foreign')) {
            Schema::table('guide_applications', function ($table) {
                $table->foreign('user_id')->references('id')->on('users');
            });
        }
    }

    /**
     * Whether a foreign key constraint with the given name exists on the
     * given table — Schema::hasColumn()/hasTable() have no FK equivalent,
     * so query information_schema directly (portable, no Doctrine DBAL dep).
     */
    protected function foreignKeyExists(string $table, string $constraintName): bool
    {
        return DB::table('information_schema.TABLE_CONSTRAINTS')
            ->where('CONSTRAINT_SCHEMA', DB::getDatabaseName())
            ->where('TABLE_NAME', $table)
            ->where('CONSTRAINT_NAME', $constraintName)
            ->where('CONSTRAINT_TYPE', 'FOREIGN KEY')
            ->exists();
    }
};
