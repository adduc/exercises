<ul>
    @foreach ($businesses as $business)
        <li>{{ $business->name }}</li>
    @endforeach
</ul>

{{ $businesses->links() }}
