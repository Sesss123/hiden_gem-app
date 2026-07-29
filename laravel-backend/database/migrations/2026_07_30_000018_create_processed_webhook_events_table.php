<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create('processed_webhook_events', function (Blueprint $table) {
            $table->id();
            $table->string('source'); // 'revenuecat' | 'payhere'
            $table->string('event_id');
            $table->timestamp('created_at')->useCurrent();

            $table->unique(['source', 'event_id']);
        });
    }

    public function down()
    {
        Schema::dropIfExists('processed_webhook_events');
    }
};
