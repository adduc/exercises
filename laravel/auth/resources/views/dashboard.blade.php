@extends('layouts.app')

@section('title', 'Dashboard')

@section('content')
    <form method="POST" action="{{ route('logout') }}">
        @csrf
        <a href="{{ route('logout') }}"
           onclick="event.preventDefault();
                         this.closest('form').submit();">
            {{ __('Logout') }}
    </form>
@endsection
