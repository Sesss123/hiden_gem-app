<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DatasetImport extends Model
{
    protected $fillable = ['filename', 'record_count', 'user_id'];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
