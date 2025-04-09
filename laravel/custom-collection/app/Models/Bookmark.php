<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations;

class Bookmark extends Model
{
    protected $fillable = ['url'];

    public function user(): Relations\BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
