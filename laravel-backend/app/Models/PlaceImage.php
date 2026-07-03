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

    /**
     * BUG-058: Cascade delete is defined at the database level.
     * The migration for place_images must include:
     *   $table->foreign('place_id')->references('id')->on('places')->onDelete('cascade');
     * This ensures rows are automatically cleaned up when the parent Place is deleted.
     */
    public function place(): BelongsTo
    {
        return $this->belongsTo(Place::class, 'place_id', 'id');
    }
}
