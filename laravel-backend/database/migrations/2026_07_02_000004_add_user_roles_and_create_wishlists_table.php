<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        // Add role and subscription_tier to users table
        Schema::table('users', function (Blueprint $table) {
            if (!Schema::hasColumn('users', 'role')) {
                $table->string('role')->default('tourist')->after('email');
            }
            if (!Schema::hasColumn('users', 'subscription_tier')) {
                $table->string('subscription_tier')->default('Free')->after('role'); // 'Free', 'PRO', 'VIP'
            }
        });

        // Add access_tier to places table for VIP/PRO exclusive hidden gems
        Schema::table('places', function (Blueprint $table) {
            if (!Schema::hasColumn('places', 'access_tier')) {
                $table->string('access_tier')->default('Free')->after('category'); // 'Free', 'PRO', 'VIP'
            }
        });

        // Create wishlists table for user bookmarks/favorites
        if (!Schema::hasTable('wishlists')) {
            Schema::create('wishlists', function (Blueprint $table) {
                $table->id();
                $table->foreignId('user_id')->constrained()->onDelete('cascade');
                $table->foreignId('place_id')->constrained()->onDelete('cascade');
                $table->timestamps();

                // A user can bookmark a specific place only once
                $table->unique(['user_id', 'place_id']);
            });
        }
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('wishlists');

        Schema::table('places', function (Blueprint $table) {
            $table->dropColumn('access_tier');
        });

        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['role', 'subscription_tier']);
        });
    }
};
