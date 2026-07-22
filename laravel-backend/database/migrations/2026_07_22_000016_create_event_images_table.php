<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create('event_images', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('event_id')->index();
            $table->string('thumb_path');
            $table->string('full_path');
            $table->boolean('is_cover')->default(false)->index();
            $table->integer('sort_order')->default(0);
            $table->unsignedBigInteger('sync_version')->default(0)->index();
            $table->timestamps();

            $table->foreign('event_id')
                  ->references('id')->on('events')
                  ->onDelete('cascade');
        });
    }

    public function down()
    {
        Schema::dropIfExists('event_images');
    }
};
