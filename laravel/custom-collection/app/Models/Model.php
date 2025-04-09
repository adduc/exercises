<?php

namespace App\Models;

use App\Support;
use Illuminate\Database\Eloquent\Model as EloquentModel;

class Model extends EloquentModel
{
    public function newCollection(array $models = []): Support\ModelCollection
    {
        return new Support\ModelCollection($models);
    }
}
