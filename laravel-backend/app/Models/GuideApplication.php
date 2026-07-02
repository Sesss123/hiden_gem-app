<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class GuideApplication extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'license_number',
        'bio',
        'category',
        'license_doc_url',
        'nic_doc_url',
        'selfie_doc_url',
        'status',
        'applied_at',
    ];

    protected $casts = [
        'applied_at' => 'datetime',
    ];

    /**
     * Get the user that owns the guide application.
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
