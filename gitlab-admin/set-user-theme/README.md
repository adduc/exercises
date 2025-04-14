# Setting a user's theme in GitLab through the Rails Console

This exercise shows how GitLab's Rails console can be used to set a
user's theme. This is useful during automated setups or in situations
where impersonating a user is not enabled in GitLab.

## Context

I occasionally need to provision a GitLab instance locally to test
configuration changes. While GitLab provides configuration settings in
their server configuration, it is partially broken due to changes in
how the dark/light themes are handled. This exercise demonstrates how
to set a user's theme directly through the Rails console, which allows
setting dark mode for a user.
