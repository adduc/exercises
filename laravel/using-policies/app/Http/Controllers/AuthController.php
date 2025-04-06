<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

use App\Models;
use Illuminate\Auth\AuthManager;
use Illuminate\Contracts\Hashing\Hasher;

class AuthController extends Controller
{
    public function __construct(
        protected AuthManager $authManager,
        protected Hasher $hasher,
    ) {}

    public function showRegisterForm()
    {
        return view('auth.register');
    }

    public function register(Request $request)
    {
        $request->validate([
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:8|max:255|confirmed',
        ]);

        $user = Models\User::create([
            'email' => $request->email,
            'password' => $this->hasher->make($request->password),
        ]);

        $this->authManager->login($user);

        return redirect()
            ->route('dashboard')
            ->with('success', 'Registration successful. Welcome!');
    }

    public function showLoginForm()
    {
        return view('auth.login');
    }

    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required|string',
        ]);

        if ($this->authManager->attempt($request->only('email', 'password'))) {
            $route = route('dashboard');
            return redirect()->intended($route)
                ->with('success', 'Logged in successfully.');
        }

        return back()->withErrors(['email' => 'Invalid credentials.']);
    }

    public function logout(Request $request)
    {
        $this->authManager->logout();

        return redirect()->route('login.form')
            ->with('success', 'Logged out successfully.');
    }
}
