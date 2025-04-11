<?php

use App\Http\Requests\QueryRequest;
use Illuminate\Support\Facades\Route;

Route::get('/', function (QueryRequest $request) {
    dd($request->validated());
    return view('welcome');
});
