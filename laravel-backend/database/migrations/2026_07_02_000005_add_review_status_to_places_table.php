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
        Schema::table('places', function (Blueprint $table) {
            $table->string('status', 20)->default('approved')->index()->after('access_tier');
            $table->unsignedBigInteger('reviewed_by')->nullable()->after('status');
            $table->text('review_reason')->nullable()->after('reviewed_by');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('places', function (Blueprint $table) {
            $table->dropColumn(['status', 'reviewed_by', 'review_reason']);
        });
    }
};
