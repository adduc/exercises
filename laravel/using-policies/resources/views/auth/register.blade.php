@extends('layouts.app')

@section('title', 'Register')

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

<form method="post" action="{{ route('register') }}">
    @csrf
    <label for="email">Email:</label>
    <input type="email" id="email" name="email" required value="{{ old('email') }}"><br><br>

    <label for="password">Password:</label>
    <input type="password" id="password" name="password" required><br><br>

    <label for="password_confirmation">Confirm Password:</label>
    <input type="password" id="password_confirmation" name="password_confirmation" required><br><br>

    <button type="submit">Register</button>
</form>
<p>Already have an account? <a href="{{ route('login') }}">Login here</a></p>

@endsection
