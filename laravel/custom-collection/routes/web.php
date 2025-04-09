<?php

use Illuminate\Support\Facades\Route;

use App\Models;

Route::get('/', function () {

    $users = Models\User::all();

    $users->loadMissingCount(['bookmarks']);

    return view('welcome', compact('users'));
});
