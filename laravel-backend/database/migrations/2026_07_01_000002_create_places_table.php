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
        Schema::create('places', function (Blueprint $table) {
            $table->string('id', 100)->primary();
            $table->string('name');
            $table->text('description')->nullable();
            $table->string('district')->index();
            $table->string('province')->nullable();
            $table->string('category')->index();
            $table->decimal('lat', 10, 7)->default(0.0);
            $table->decimal('lng', 10, 7)->default(0.0);
            $table->decimal('rating', 3, 2)->default(0.0);
            $table->string('ticket_range')->nullable();
            $table->string('ticket_price')->nullable();
            
            // Curated Travel, Safety & Access details (Unique Value Proposition)
            $table->string('opening_hours')->nullable();
            $table->string('mobile_signal')->nullable();
            $table->string('road_type')->nullable();
            $table->string('road_condition')->nullable();
            $table->string('vehicle_access')->nullable();
            $table->text('activities')->nullable();
            $table->string('tourist_popularity')->nullable();
            $table->string('family_friendly')->nullable();
            $table->string('budget_category')->nullable();
            $table->string('parking_avail')->nullable();
            $table->string('parking_range')->nullable();
            $table->string('toilets')->nullable();
            $table->string('food_nearby')->nullable();
            $table->string('wheelchair_access')->nullable();
            $table->string('camping_allowed')->nullable();
            $table->string('safety_level')->nullable();
            $table->string('wildlife_hazard')->nullable();
            $table->string('guide_required')->nullable();
            $table->string('rain_sensitivity')->nullable();
            $table->string('monsoon_note')->nullable();
            $table->string('best_time')->nullable();
            $table->string('best_time_to_visit')->nullable();
            $table->string('height_m')->nullable();
            $table->string('length_km')->nullable();
            $table->string('surfing')->nullable();
            $table->string('access_tier')->default('Free')->index();
            
            $table->json('risk_tags')->nullable();
            $table->json('facilities')->nullable();
            
            // AR & Heritage features
            $table->boolean('ar_supported')->default(false)->index();
            $table->unsignedTinyInteger('ar_tier')->default(3);
            $table->string('ar_brand_name')->nullable();
            $table->string('ar_model_url')->nullable();
            $table->string('ar_historical_model_url')->nullable();
            $table->decimal('ar_model_scale', 8, 4)->default(0.0100);
            $table->string('historical_period')->nullable();
            $table->decimal('ar_file_size_mb', 8, 2)->default(0.00);
            $table->string('audio_guide_url_si')->nullable();
            $table->string('audio_guide_url_en')->nullable();
            $table->string('geohash', 20)->nullable()->index();
            
            // Primary display image URL (fallback if place_images empty)
            $table->text('image_url')->nullable();
            
            // Option A Synchronization Engine columns
            $table->unsignedBigInteger('sync_version');
            $table->boolean('is_deleted')->default(false)->index();
            
            $table->timestamps();
            
            // Enforce unique index on sync_version as agreed in System Architecture v3.3
            $table->unique('sync_version');

            // Composite indices for common query patterns (BUG-037)
            $table->index(['is_deleted', 'district']);
            $table->index(['is_deleted', 'category']);
            $table->index(['is_deleted', 'ar_supported']);
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('places');
    }
};
