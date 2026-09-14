<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('travel_alerts', function (Blueprint $table) {
            $table->id();
            $table->string('type', 32);
            $table->unsignedTinyInteger('level');
            $table->string('title');
            $table->text('message');
            $table->string('source', 120);
            $table->json('districts')->nullable();
            $table->json('river_basins')->nullable();
            $table->json('hazard_geometry')->nullable();
            $table->timestampTz('starts_at');
            $table->timestampTz('expires_at');
            $table->boolean('is_active')->default(false);
            $table->foreignId('published_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
            $table->index(['is_active', 'starts_at', 'expires_at']);
            $table->index(['type', 'level']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('travel_alerts');
    }
};
