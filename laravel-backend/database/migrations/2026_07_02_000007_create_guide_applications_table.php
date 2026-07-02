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
        Schema::create('guide_applications', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('license_number');
            $table->text('bio')->nullable();
            $table->string('category', 100);
            $table->string('license_doc_url', 500)->nullable();
            $table->string('nic_doc_url', 500)->nullable();
            $table->string('selfie_doc_url', 500)->nullable();
            $table->string('status', 20)->default('pending'); // 'pending', 'approved', 'rejected'
            $table->timestamp('applied_at')->useCurrent();
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
        Schema::dropIfExists('guide_applications');
    }
};
