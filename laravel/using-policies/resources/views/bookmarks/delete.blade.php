@extends('layouts.app')

@section('title', 'Delete Bookmark')

@section('content')

<!-- Display a confirmation message before deletion -->

Are you sure you want to delete this bookmark?

<p><strong>URL:</strong> {{ $bookmark->url }}</p>
<p><strong>Note:</strong> {{ $bookmark->note ?? 'No note provided' }}</p>
<p>This action cannot be undone.</p>

<form action="{{ route('bookmarks.destroy', $bookmark->id) }}" method="POST">
    @csrf
    @method('DELETE')
    <button type="submit">Delete Bookmark</button>
</form>

@endsection
