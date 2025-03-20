<?php

/** @var \Laravel\Lumen\Routing\Router $router */

use App\Models\User;
use Illuminate\Http\Request;

/*
|--------------------------------------------------------------------------
| Application Routes
|--------------------------------------------------------------------------
|
| Here is where you can register all of the routes for an application.
| It is a breeze. Simply tell Lumen the URIs it should respond to
| and give it the Closure to call when that URI is requested.
|
*/

$router->get('/', fn () => view('index'));


$router->get('/register', fn () => view('register'));
$router->post('/register', function (Request $request) {

    $data = $this->validate($request, [
        'email' => 'required|email|unique:'. User::class,
        'password' => 'required|min:6',
        'confirm_password' => 'required|same:password',
    ]);

    $data['password'] = password_hash($data['password'], PASSWORD_DEFAULT);

    $user = User::create([
        'email' => $data['email'],
        'password' => $data['password'],
    ]);

    return redirect('/login');
});


$router->get('/login', fn () => view('login'));