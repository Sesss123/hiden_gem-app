<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('dataset_imports', function (Blueprint $table) {
            if (!Schema::hasColumn('dataset_imports', 'file_hash')) {
                $table->string('file_hash', 64)->nullable()->index()->after('filename');
            }
            if (!Schema::hasColumn('dataset_imports', 'batch_id')) {
                $table->string('batch_id', 36)->nullable()->index()->after('file_hash');
            }
            if (!Schema::hasColumn('dataset_imports', 'imported_count')) {
                $table->integer('imported_count')->default(0)->after('record_count');
            }
            if (!Schema::hasColumn('dataset_imports', 'skipped_count')) {
                $table->integer('skipped_count')->default(0)->after('imported_count');
            }
            if (!Schema::hasColumn('dataset_imports', 'duplicate_count')) {
                $table->integer('duplicate_count')->default(0)->after('skipped_count');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('dataset_imports', function (Blueprint $table) {
            $cols = ['file_hash', 'batch_id', 'imported_count', 'skipped_count', 'duplicate_count'];
            foreach ($cols as $col) {
                if (Schema::hasColumn('dataset_imports', $col)) {
                    $table->dropColumn($col);
                }
            }
        });
    }
};
