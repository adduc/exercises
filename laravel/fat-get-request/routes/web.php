<?php

use App\Http\Requests\QueryRequest;
use Illuminate\Support\Facades\Route;

Route::get('/', function (QueryRequest $request) {
    return [
        'all' => $request->all('a'),
        'get' => $request->get('a'),
        'query' => $request->query('a'),
        'input' => $request->input('a'),
        'validated' => $request->validated()['a'] ?? null,
    ];
});
