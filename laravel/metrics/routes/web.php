<?php

use App\Events\SampleEvent;
use App\Jobs\SampleJob;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/dispatch/event', function () {
    SampleEvent::dispatch(random_int(PHP_INT_MIN, PHP_INT_MAX));
});

Route::get('/dispatch/job', function () {
    SampleJob::dispatch(random_int(PHP_INT_MIN, PHP_INT_MAX));
});
