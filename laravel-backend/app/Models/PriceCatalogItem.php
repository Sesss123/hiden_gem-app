<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Cache;

class PriceCatalogItem extends Model
{
    protected $table = 'price_catalog';

    protected $fillable = ['key', 'category', 'label', 'display_mode', 'amount',
        'max_amount', 'currency', 'billing_period', 'source', 'effective_from',
        'expires_at', 'is_active', 'updated_by'];

    protected $casts = [
        'amount' => 'decimal:2', 'max_amount' => 'decimal:2', 'is_active' => 'boolean',
        'effective_from' => 'datetime', 'expires_at' => 'datetime',
    ];

    protected static function booted()
    {
        static::saved(fn () => static::invalidatePublicCache());
        static::deleted(fn () => static::invalidatePublicCache());
    }

    public static function invalidatePublicCache(): void
    {
        Cache::forget('public_price_catalog_v1');
        $version = (int) Cache::get('public_price_catalog_version', 0);
        Cache::forever('public_price_catalog_version', $version + 1);
    }

    public function updater()
    {
        return $this->belongsTo(User::class, 'updated_by');
    }

    public function scopeCurrentlyAvailable($query)
    {
        return $query->where('is_active', true)
            ->where(fn ($q) => $q->whereNull('effective_from')->orWhere('effective_from', '<=', now()))
            ->where(fn ($q) => $q->whereNull('expires_at')->orWhere('expires_at', '>', now()));
    }

    public function toPublicArray(): array
    {
        return array_filter([
            'key' => $this->key,
            'category' => $this->category,
            'label' => $this->label,
            'display_mode' => $this->display_mode,
            'amount' => $this->amount === null ? null : (float) $this->amount,
            'max_amount' => $this->max_amount === null ? null : (float) $this->max_amount,
            'currency' => $this->currency,
            'billing_period' => $this->billing_period,
            'source' => $this->source,
            'effective_from' => $this->effective_from?->toIso8601String(),
            'expires_at' => $this->expires_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ], fn ($value) => $value !== null);
    }
}
