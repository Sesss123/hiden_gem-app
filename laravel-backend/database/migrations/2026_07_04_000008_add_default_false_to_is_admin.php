<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        // BUG-C01 Fix: Enforce default(false) on is_admin column
        if (Schema::hasColumn('users', 'is_admin')) {
            try {
                Schema::table('users', function (Blueprint $table) {
                    $table->boolean('is_admin')->default(false)->change();
                });
            } catch (\Exception $e) {
                // BUG-007 Fix: Log exception instead of silent failure
                \Log::warning("Migration failed to change is_admin default: " . $e->getMessage());
            }

            // First ensure canonical admin seeder account retains super_admin role and admin rights
            DB::table('users')
                ->where('email', 'admin@hiddengemssl.com')
                ->update(['role' => 'super_admin', 'is_admin' => true]);

            // Corrective data migration: set is_admin = false for all users whose role is not admin or super_admin
            DB::table('users')
                ->whereNotIn('role', ['admin', 'super_admin'])
                ->where('email', '!=', 'admin@hiddengemssl.com')
                ->update(['is_admin' => false]);
        }
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        if (Schema::hasColumn('users', 'is_admin')) {
            try {
                Schema::table('users', function (Blueprint $table) {
                    $table->boolean('is_admin')->default(true)->change();
                });
            } catch (\Exception $e) {}
        }
    }
};
