<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::table('place_images', function (Blueprint $table) {
            $table->enum('status', ['processing', 'ready', 'failed'])->default('ready')->after('sort_order');
        });

        Schema::table('event_images', function (Blueprint $table) {
            $table->enum('status', ['processing', 'ready', 'failed'])->default('ready')->after('sort_order');
        });
    }

    public function down()
    {
        Schema::table('place_images', function (Blueprint $table) {
            $table->dropColumn('status');
        });

        Schema::table('event_images', function (Blueprint $table) {
            $table->dropColumn('status');
        });
    }
};
