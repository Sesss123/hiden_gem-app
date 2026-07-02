<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SyncCounter extends Model
{
    protected $table = 'sync_counter';
    public $timestamps = false;
    protected $fillable = ['id', 'current_version'];
}
