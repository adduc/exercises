@extends('layouts.app')

@section('title', 'Edit Bookmark')

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

<form method="POST" action="{{ route('bookmarks.update', $bookmark->id) }}">
    @csrf
    @method('PUT')

    <label for="url">URL:</label>
    <input type="url" id="url" name="url" required value="{{ old('url', $bookmark->url) }}"><br><br>

    <label for="note">Note:</label>
    <textarea id="note" name="note" rows="4" cols="50">{{ old('note', $bookmark->note) }}</textarea><br><br>

    <button type="submit">Update Bookmark</button>
</form>


@endsection
