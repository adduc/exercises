@extends('layouts.app')

@section('title', 'Create Bookmark')

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

<form method="POST" action="{{ route('bookmarks.store') }}">
    @csrf
    <label for="url">URL:</label>
    <input type="url" id="url" name="url" required value="{{ old('url') }}"><br><br>

    <label for="note">Note:</label>
    <textarea id="note" name="note" rows="4" cols="50">{{ old('note') }}</textarea><br><br>

    <button type="submit">Create Bookmark</button>

</form>

@endsection
