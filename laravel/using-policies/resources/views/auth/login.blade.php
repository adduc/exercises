@extends('layouts.app')

@section('title', 'Login')

@section('content')

@if ($errors->any())
    <div style="color: red;">
        <strong>Whoops!</strong> There were some problems with your input.<br><br>
        <ul>
            @foreach ($errors->all() as $error)
                <li>{{ $error }}</li>
            @endforeach
        </ul>
    </div>
@endif

<form method="post" action="{{ route('login') }}">
    @csrf
    <label for="email">Email:</label>
    <input type="email" id="email" name="email" required value="{{ old('email') }}"><br><br>

    <label for="password">Password:</label>
    <input type="password" id="password" name="password" required><br><br>

    <button type="submit">Login</button>
</form>
<p>Don't have an account? <a href="{{ route('register') }}">Register here</a></p>

@endsection
