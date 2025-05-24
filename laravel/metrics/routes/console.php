<?php

use Illuminate\Support\Facades\Schedule;

// Schedule::call(function () {
//     echo "Hi!\n";
// })->everySecond();

Schedule::command('optimize')->everySecond();
