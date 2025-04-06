# Using policies in Laravel

This exercise shows how policies can be used in a Laravel application to authorize user actions on models.

## Context

I am working on a Laravel application with user-specific ownership of resources. While I have implement authorization in Laravel codebases in the past, they were typically done through role-based access control or hard-coded checks in controller actions.

## Lessons Learned

There are multiple overlapping solutions for authorization within Laravel, and it is important to establish a clear strategy for development teams to follow. Otherwise, it can lead to confusion and inconsistencies in the codebase. For example, FormRequests have their own authorization methods, Gates can be used for quick checks, and Policies can be used for more complex model-based authorization.

In my opinion, Policies and Gates can be used in complementary ways. Gates are great for actions (does user have access to a report, to perform an export, etc.), while Policies are more suited for typical CRUD operations on models. This allows for a clear separation of concerns, where Gates handle more granular permissions and Policies handle broader model-based permissions.
