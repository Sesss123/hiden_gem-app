<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Cache;

class AppSetting extends Model
{
    use HasFactory;

    protected $table = 'app_settings';

    protected $fillable = [
        'key',
        'value',
        'type',
        'description',
        'updated_by',
    ];

    /**
     * Relationship to the user who last updated this setting.
     */
    public function updater()
    {
        return $this->belongsTo(User::class, 'updated_by');
    }

    /**
     * Get a setting value by key with memory/cache lookup.
     *
     * @param string $key
     * @param mixed $default
     * @return mixed
     */
    public static function get(string $key, $default = null)
    {
        $cacheKey = "app_setting_{$key}";

        return Cache::remember($cacheKey, 300, function () use ($key, $default) {
            $setting = static::where('key', $key)->first();
            if (!$setting) {
                return $default;
            }

            return static::castValue($setting->value, $setting->type);
        });
    }

    /**
     * Set a setting value by key and invalidate cache.
     *
     * @param string $key
     * @param mixed $value
     * @param int|null $updatedBy
     * @param string|null $type
     * @param string|null $description
     * @return static
     */
    public static function set(string $key, $value, ?int $updatedBy = null, ?string $type = null, ?string $description = null)
    {
        $setting = static::firstOrNew(['key' => $key]);
        
        $setting->value = is_bool($value) ? ($value ? '1' : '0') : (string) $value;
        if ($type) {
            $setting->type = $type;
        }
        if ($description) {
            $setting->description = $description;
        }
        if ($updatedBy) {
            $setting->updated_by = $updatedBy;
        }
        $setting->save();

        Cache::forget("app_setting_{$key}");

        return $setting;
    }

    /**
     * Helper to check if ads are enabled across apps.
     *
     * @return bool
     */
    public static function isAdsEnabled(): bool
    {
        return (bool) static::get('ads_enabled', true);
    }

    /**
     * Cast string value from DB to appropriate PHP type.
     */
    protected static function castValue($value, string $type)
    {
        if ($value === null) {
            return null;
        }

        switch ($type) {
            case 'boolean':
                return filter_var($value, FILTER_VALIDATE_BOOLEAN);
            case 'integer':
                return (int) $value;
            case 'json':
                return json_decode($value, true);
            default:
                return $value;
        }
    }
}
