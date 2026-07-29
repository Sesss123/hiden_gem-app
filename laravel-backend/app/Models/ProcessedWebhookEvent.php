<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ProcessedWebhookEvent extends Model
{
    protected $table = 'processed_webhook_events';
    public $timestamps = false;
    protected $fillable = ['source', 'event_id', 'created_at'];
}
