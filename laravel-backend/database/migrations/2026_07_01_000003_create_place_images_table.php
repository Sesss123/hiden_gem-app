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
        Schema::create('place_images', function (Blueprint $table) {
            $table->id();
            $table->string('place_id', 36)->index();
            $table->string('thumb_path');
            $table->string('full_path');
            $table->boolean('is_cover')->default(false)->index();
            $table->integer('sort_order')->default(0);
            $table->unsignedBigInteger('sync_version')->index();
            $table->timestamps();

            $table->foreign('place_id')
                  ->references('id')->on('places')
                  ->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('place_images');
    }
};
