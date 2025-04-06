<?php

namespace App\Policies;

use App\Models\Bookmark;
use App\Models\User;
use Illuminate\Auth\Access\Response;

class BookmarkPolicy
{
    /**
     * Determine whether the user can update the model.
     */
    public function update(User $user, Bookmark $bookmark): bool
    {
        return $user->id === $bookmark->user_id;
    }

    /**
     * Determine whether the user can delete the model.
     */
    public function delete(User $user, Bookmark $bookmark): bool
    {
        return $user->id === $bookmark->user_id;
    }
}
