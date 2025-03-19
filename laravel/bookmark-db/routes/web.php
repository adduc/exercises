<?php

use App\Models\Bookmark;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {

    Bookmark::create([
        'Url' => 'http://example.com',
    ]);

    return "";
});
