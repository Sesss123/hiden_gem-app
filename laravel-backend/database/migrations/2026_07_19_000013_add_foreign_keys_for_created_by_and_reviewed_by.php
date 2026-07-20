<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * places.created_by, places.reviewed_by, and events.created_by were
     * added as plain unsignedBigInteger columns with no FK constraint to
     * users.id — the DB never enforces referential integrity on them even
     * though app code treats them as user references (ownership checks in
     * PlaceController/EventController, ->belongsTo(User::class) on both
     * models). Add the missing constraints. nullOnDelete() matches the
     * columns' existing nullable/optional semantics: deleting a user (e.g. a
     * removed content_manager) orphans their created places/events to
     * "no creator" rather than either cascading (destroying real content)
     * or blocking the user delete outright.
     */
    public function up(): void
    {
        if (Schema::hasColumn('places', 'created_by') && !$this->foreignKeyExists('places', 'places_created_by_foreign')) {
            Schema::table('places', function (Blueprint $table) {
                $table->foreign('created_by')->references('id')->on('users')->nullOnDelete();
            });
        }

        if (Schema::hasColumn('places', 'reviewed_by') && !$this->foreignKeyExists('places', 'places_reviewed_by_foreign')) {
            Schema::table('places', function (Blueprint $table) {
                $table->foreign('reviewed_by')->references('id')->on('users')->nullOnDelete();
            });
        }

        if (Schema::hasColumn('events', 'created_by') && !$this->foreignKeyExists('events', 'events_created_by_foreign')) {
            Schema::table('events', function (Blueprint $table) {
                $table->foreign('created_by')->references('id')->on('users')->nullOnDelete();
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if ($this->foreignKeyExists('places', 'places_created_by_foreign')) {
            Schema::table('places', function (Blueprint $table) {
                $table->dropForeign('places_created_by_foreign');
            });
        }

        if ($this->foreignKeyExists('places', 'places_reviewed_by_foreign')) {
            Schema::table('places', function (Blueprint $table) {
                $table->dropForeign('places_reviewed_by_foreign');
            });
        }

        if ($this->foreignKeyExists('events', 'events_created_by_foreign')) {
            Schema::table('events', function (Blueprint $table) {
                $table->dropForeign('events_created_by_foreign');
            });
        }
    }

    /**
     * Whether a foreign key constraint with the given name exists on the
     * given table — Schema::hasColumn()/hasTable() have no FK equivalent,
     * so query information_schema directly (portable, no Doctrine DBAL dep).
     * Mirrors the helper in 2026_07_10_113915_change_user_id_to_string_on_guide_applications_table.php.
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
