<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class EventImage extends Model
{
    protected $table = 'event_images';

    protected $fillable = [
        'event_id', 'thumb_path', 'full_path', 'is_cover',
        'sort_order', 'sync_version'
    ];

    protected $casts = [
        'is_cover' => 'boolean',
        'sort_order' => 'integer',
        'sync_version' => 'integer'
    ];

    public function event(): BelongsTo
    {
        return $this->belongsTo(Event::class, 'event_id', 'id');
    }
}
