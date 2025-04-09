@foreach ($users as $user)
    <p>{{ $user->name }}: {{ $user->bookmarks_count }} bookmark(s)</p>
@endforeach
