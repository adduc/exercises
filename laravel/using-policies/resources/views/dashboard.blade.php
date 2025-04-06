@extends('layouts.app')

@section('title', 'Dashboard')

@section('content')
    <form style="display:inline;" method="POST" action="{{ route('logout') }}">
        @csrf
        <a href="{{ route('logout') }}"
           onclick="event.preventDefault();
                         this.closest('form').submit();">
            {{ __('Logout') }}
        </a>
    </form>
    /
    <a href="{{ route('bookmarks.index') }}">
        {{ __('Bookmarks') }}
    </a>
@endsection
