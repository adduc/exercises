# Using custom collections in Laravel

This exercise demostrates how custom collections can be used to extend the functionality of Laravel's Eloquent collections.

## Context

I am working on a Laravel project that makes use of relationship counts and View components. While Eloquent's loadCount works great for eager loading relationship counts, I wanted to extend the functionality to include a custom collection that can load missing relationship counts when they are not already loaded.

## Lessons Learned

Within PHP, attributes are not inherited. This meant that using Laravel's CollectedBy attribute on a base model did not work to cause all child models to use the custom collection. Instead, I had to use the `newCollection` method to allow the base model's configuration to affect the child models.
