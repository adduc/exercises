<?php

namespace App\Http\Controllers;

use App\Models\Bookmark;
use Illuminate\Contracts\Auth\{Access\Gate, Guard};
use Illuminate\Http\Request;

class BookmarkController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index(Guard $guard)
    {
        // fetch all bookmarks for the authenticated user
        $bookmarks = Bookmark::where('user_id', $guard->id())->get();

        // return the view with bookmarks
        return view('bookmarks.index', compact('bookmarks'));
    }

    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        // Show the form to create a new bookmark
        return view('bookmarks.create');
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Guard $guard, Request $request)
    {
        // Validate the request data
        $validatedData = $request->validate([
            'url' => ['required', 'string', 'url', 'max:2048'],
            'note' => ['nullable', 'string', 'max:2048'],
        ]);

        // Create a new bookmark for the authenticated user
        $bookmark = new Bookmark();
        $bookmark->user_id = $guard->id();
        $bookmark->url = $validatedData['url'];
        $bookmark->note = $validatedData['note'] ?? null;

        // Save the bookmark to the database
        $bookmark->save();

        // Redirect to the bookmarks index with a success message
        return redirect()->route('bookmarks.index')
            ->with('success', 'Bookmark created successfully.');
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(Gate $gate, Bookmark $bookmark)
    {
        // Verify the bookmark belongs to the user (@see BookmarkPolicy)
        $gate->authorize('update', $bookmark);

        // Show the edit form for the bookmark
        return view('bookmarks.edit', compact('bookmark'));
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Gate $gate, Request $request, Bookmark $bookmark)
    {
        // Verify the bookmark belongs to the user (@see BookmarkPolicy)
        $gate->authorize('update', $bookmark);

        // Validate the request data
        $validatedData = $request->validate([
            'url' => ['required', 'string', 'url', 'max:2048'],
            'note' => ['nullable', 'string', 'max:2048'],
        ]);

        // Update the bookmark with the validated data
        $bookmark->url = $validatedData['url'];
        $bookmark->note = $validatedData['note'] ?? null;

        // Save the updated bookmark to the database
        $bookmark->save();

        // Redirect to the bookmarks index with a success message
        return redirect()->route('bookmarks.index')
            ->with('success', 'Bookmark updated successfully.');
    }

    public function delete(Gate $gate, Bookmark $bookmark)
    {
        // Verify the bookmark belongs to the user (@see BookmarkPolicy)
        $gate->authorize('delete', $bookmark);

        // Show the delete confirmation view
        return view('bookmarks.delete', compact('bookmark'));
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Gate $gate, Bookmark $bookmark)
    {
        // Verify the bookmark belongs to the user (@see BookmarkPolicy)
        $gate->authorize('delete', $bookmark);

        // Delete the bookmark from the database
        $bookmark->delete();

        // Redirect to the bookmarks index with a success message
        return redirect()->route('bookmarks.index')
            ->with('success', 'Bookmark deleted successfully.');
    }
}
