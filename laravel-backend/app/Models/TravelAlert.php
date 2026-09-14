<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class TravelAlert extends Model
{
    protected $fillable = [
        'type', 'level', 'title', 'message', 'source', 'districts',
        'river_basins', 'hazard_geometry', 'starts_at', 'expires_at',
        'is_active', 'published_by',
    ];

    protected $casts = [
        'districts' => 'array',
        'river_basins' => 'array',
        'hazard_geometry' => 'array',
        'starts_at' => 'datetime',
        'expires_at' => 'datetime',
        'is_active' => 'boolean',
    ];
}
