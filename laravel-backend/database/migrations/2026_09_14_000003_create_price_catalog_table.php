<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create('price_catalog', function (Blueprint $table) {
            $table->id();
            $table->string('key', 96)->unique();
            $table->string('category', 48)->index();
            $table->string('label', 160);
            $table->enum('display_mode', ['unavailable', 'contact', 'free', 'fixed', 'from', 'range'])->default('unavailable');
            $table->decimal('amount', 14, 2)->nullable();
            $table->decimal('max_amount', 14, 2)->nullable();
            $table->char('currency', 3)->nullable();
            $table->string('billing_period', 32)->nullable();
            $table->string('source', 255)->nullable();
            $table->timestamp('effective_from')->nullable();
            $table->timestamp('expires_at')->nullable();
            $table->boolean('is_active')->default(true)->index();
            $table->unsignedBigInteger('updated_by')->nullable();
            $table->timestamps();

            $table->foreign('updated_by')->references('id')->on('users')->nullOnDelete();
            $table->index(['is_active', 'effective_from', 'expires_at']);
        });
    }

    public function down()
    {
        Schema::dropIfExists('price_catalog');
    }
};
