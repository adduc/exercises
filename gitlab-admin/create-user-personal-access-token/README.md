# Creating a personal access token for GitLab through the Rails Console

This exercise shows how GitLab's Rails console can be used to create a personal access token for a user. This is useful during automated setups where subsequent tasks require interaction with the GitLab API.

## Context

I occasionally need to provision a GitLab instance locally to test
configuration changes, but want to be able to scrap and recreate the instance at will. As best as I can tell, GitLab does not provide a
built-in way to automate the creation of personal access tokens through the initial setup process.
