<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PlaceImage extends Model
{
    protected $table = 'place_images';

    protected $fillable = [
        'place_id', 'thumb_path', 'full_path', 'is_cover',
        'sort_order', 'sync_version'
    ];

    protected $casts = [
        'is_cover' => 'boolean',
        'sort_order' => 'integer',
        'sync_version' => 'integer'
    ];

    public function place(): BelongsTo
    {
        return $this->belongsTo(Place::class, 'place_id', 'id');
    }
}
