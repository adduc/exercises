@extends('layouts.app')

@section('title', 'Bookmarks')

@section('content')

<a href="{{ route('bookmarks.create') }}">Create Bookmark</a>

@if ($bookmarks->isEmpty())
<p>No bookmarks found.</p>
@else
@foreach ($bookmarks as $bookmark)
<details>
    <summary>{{ $bookmark->url }}</summary>
    <p>{{ $bookmark->note ?? 'No note provided' }}</p>

    <a href="{{ route('bookmarks.edit', $bookmark->id) }}">
        {{ __('Edit') }}
    </a>
    /
    <a href="{{ route('bookmarks.delete', $bookmark->id) }}">
        {{ __('Delete') }}
    </a>
</details>
@endforeach
@endif

@endsection
