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
        Schema::table('guide_applications', function (Blueprint $table) {
            if (!Schema::hasColumn('guide_applications', 'email')) {
                $table->string('email')->nullable()->after('user_id');
            }
            if (!Schema::hasColumn('guide_applications', 'name')) {
                $table->string('name')->nullable()->after('email');
            }
            if (!Schema::hasColumn('guide_applications', 'admin_comment')) {
                $table->text('admin_comment')->nullable()->after('status');
            }
            if (!Schema::hasColumn('guide_applications', 'reviewed_at')) {
                $table->timestamp('reviewed_at')->nullable()->after('applied_at');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('guide_applications', function (Blueprint $table) {
            $table->dropColumn(['email', 'name', 'admin_comment', 'reviewed_at']);
        });
    }
};
