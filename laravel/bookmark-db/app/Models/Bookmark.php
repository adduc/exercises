<?php

namespace App\Models;

use BaoPham\DynamoDb\DynamoDbModel;

class Bookmark extends DynamoDbModel
{
    protected $table = 'bookmarks';

    protected $guarded = [];
}
