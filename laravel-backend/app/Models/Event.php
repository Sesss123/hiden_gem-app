<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Event extends Model
{
    use HasFactory;

    public const STATUS_PENDING = 'pending';
    public const STATUS_APPROVED = 'approved';
    public const STATUS_REJECTED = 'rejected';

    protected $fillable = [
        'name',
        'description',
        'category',
        'location',
        'date',
        'start',
        'end',
        'is_active',
        'created_by',
        'status',
        'reviewed_by',
        'review_reason',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'is_deleted' => 'boolean',
        'sync_version' => 'integer',
    ];

    protected static function booted()
    {
        static::addGlobalScope('active', function (Builder $builder) {
            $builder->where('is_deleted', false);
        });
    }

    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function images(): HasMany
    {
        return $this->hasMany(EventImage::class, 'event_id', 'id')->orderBy('sort_order');
    }

    public function coverImage(): HasOne
    {
        return $this->hasOne(EventImage::class, 'event_id', 'id')->where('is_cover', true);
    }
}
