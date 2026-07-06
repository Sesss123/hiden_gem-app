<?php

namespace App\Models;

use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

// BUG-L03 Fix: Implement MustVerifyEmail to ensure email verification in enterprise flows
class User extends Authenticatable implements MustVerifyEmail
{
    use HasApiTokens, HasFactory, Notifiable;

    // BUG-C03 Fix: Single source of truth for user role enum
    public const ROLE_TOURIST = 'tourist';
    public const ROLE_LOCAL = 'local';
    public const ROLE_GUIDE_APPROVED = 'guide_approved';
    public const ROLE_BANNED = 'banned';
    public const ROLE_ADMIN = 'admin';
    public const ROLE_SUPER_ADMIN = 'super_admin';

    public static function allRoles(): array
    {
        return [
            self::ROLE_TOURIST,
            self::ROLE_LOCAL,
            self::ROLE_GUIDE_APPROVED,
            self::ROLE_BANNED,
            self::ROLE_ADMIN,
            self::ROLE_SUPER_ADMIN,
        ];
    }

    // BUG-C01 Fix: Enforce model-level attribute default so new users never become admins
    protected $attributes = [
        'is_admin' => false,
    ];

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'name',
        'email',
        'password',
        'role',
        'subscription_tier',
        'firebase_uid',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var array<int, string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'email_verified_at' => 'datetime',
    ];

    /**
     * Get the wishlists for the user.
     */
    public function wishlists()
    {
        return $this->hasMany(Wishlist::class);
    }

    /**
     * Get the saved hidden gems for the user.
     */
    public function savedPlaces()
    {
        return $this->belongsToMany(Place::class, 'wishlists')->withTimestamps();
    }
}

