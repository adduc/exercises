<?php

namespace App\Models;

use BaoPham\DynamoDb\DynamoDbModel;
use Illuminate\Database\Eloquent\Model;

class Bookmark extends DynamoDbModel
{
    protected $table = 'bookmarks';

    protected $guarded = [];
}
