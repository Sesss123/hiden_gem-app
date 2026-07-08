<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class GuideApplication extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'email',
        'name',
        'license_number',
        'bio',
        'category',
        'license_doc_url',
        'nic_doc_url',
        'selfie_doc_url',
        'status',
        'admin_comment',
        'applied_at',
        'reviewed_at',
    ];

    protected $casts = [
        'applied_at' => 'datetime',
        'reviewed_at' => 'datetime',
    ];

    /**
     * Get the user that owns the guide application.
     * user_id stores the Firebase UID (or local user ID as a string), not the
     * users.id auto-increment PK, so this joins on the string identifier columns.
     */
    public function user()
    {
        return $this->belongsTo(User::class, 'user_id', 'firebase_uid');
    }
}
