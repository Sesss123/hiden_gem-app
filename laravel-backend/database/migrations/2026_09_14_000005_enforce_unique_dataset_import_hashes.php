<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasColumn('dataset_imports', 'updated_count')) {
            Schema::table('dataset_imports', function (Blueprint $table) {
                $table->unsignedInteger('updated_count')->default(0)->after('imported_count');
            });
        }

        // Keep all history rows. Only the first repeated entry retains its
        // hash so a unique constraint can prevent concurrent re-imports.
        $duplicates = DB::table('dataset_imports')
            ->select('file_hash', DB::raw('MIN(id) as keep_id'))
            ->whereNotNull('file_hash')
            ->groupBy('file_hash')
            ->havingRaw('COUNT(*) > 1')
            ->get();
        foreach ($duplicates as $duplicate) {
            DB::table('dataset_imports')
                ->where('file_hash', $duplicate->file_hash)
                ->where('id', '<>', $duplicate->keep_id)
                ->update(['file_hash' => null]);
        }

        Schema::table('dataset_imports', function (Blueprint $table) {
            $table->unique('file_hash', 'dataset_imports_file_hash_unique');
        });
    }

    public function down(): void
    {
        Schema::table('dataset_imports', function (Blueprint $table) {
            $table->dropUnique('dataset_imports_file_hash_unique');
            $table->dropColumn('updated_count');
        });
    }
};
