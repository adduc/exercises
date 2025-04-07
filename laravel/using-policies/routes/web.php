<?php

use App\Http\Controllers as C;
use Illuminate\Support\Facades\Route;

Route::get('/', fn () => view('landing'))->name('landing');

Route::get('/register', [C\AuthController::class, 'showRegisterForm'])->name('register.form');
Route::post('/register', [C\AuthController::class, 'register'])->name('register');
Route::get('/login', [C\AuthController::class, 'showLoginForm'])->name('login.form');
Route::post('/login', [C\AuthController::class, 'login'])->name('login');
Route::post('/logout', [C\AuthController::class, 'logout'])->name('logout');

Route::group(['middleware' => ['auth']], function () {
    Route::get('/dashboard', fn () => view('dashboard'))->name('dashboard');

    Route::get('/bookmarks/{bookmark}/delete', [C\BookmarkController::class, 'delete'])
        ->name('bookmarks.delete');

    Route::resource('bookmarks', C\BookmarkController::class)
        ->except(['show']);
});
