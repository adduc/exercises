<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {

    dd("Hello, World!");

    return view('welcome');
});
