<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('places', function (Blueprint $table) {
            $table->json('weekly_hours')->nullable()->after('opening_hours');
            $table->boolean('temporarily_closed')->default(false)->after('weekly_hours');
            $table->string('closure_note', 255)->nullable()->after('temporarily_closed');
            $table->timestamp('closure_until')->nullable()->after('closure_note');
            $table->string('holiday_hours_note', 255)->nullable()->after('closure_until');
        });
    }

    public function down(): void
    {
        Schema::table('places', function (Blueprint $table) {
            $table->dropColumn(['weekly_hours', 'temporarily_closed', 'closure_note', 'closure_until', 'holiday_hours_note']);
        });
    }
};
