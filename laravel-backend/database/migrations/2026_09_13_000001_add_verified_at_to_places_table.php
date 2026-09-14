<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('places', function (Blueprint $table) {
            $table->timestamp('verified_at')->nullable()->after('reviewed_by')->index();
        });

        // The previous admin flow assigned 4.8 without reviews. Until place
        // reviews become the authoritative aggregate, show "no rating"
        // rather than carrying synthetic scores into production.
        DB::table('places')->update(['rating' => 0.0]);
    }

    public function down(): void
    {
        Schema::table('places', function (Blueprint $table) {
            $table->dropColumn('verified_at');
        });
    }
};
