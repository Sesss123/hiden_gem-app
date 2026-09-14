<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DatasetImport extends Model
{
    protected $fillable = [
        'filename',
        'file_hash',
        'batch_id',
        'record_count',
        'imported_count',
        'updated_count',
        'skipped_count',
        'duplicate_count',
        'user_id',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
