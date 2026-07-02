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
        Schema::create('events', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->text('description')->nullable();
            $table->string('category', 100);
            $table->string('location', 255)->nullable();
            $table->string('date', 20)->nullable(); // "MM-DD" e.g., "04-13"
            $table->string('start', 20)->nullable(); // "MM-DD" e.g., "07-01"
            $table->string('end', 20)->nullable(); // "MM-DD" e.g., "08-31"
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('events');
    }
};
