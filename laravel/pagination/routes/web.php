<?php

use App\Models\Business;
use Illuminate\Pagination\Paginator;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {

    Paginator::defaultView('pagination::default');

    return view('landing', [
        'businesses' => Business::paginate(15),
    ]);
});
