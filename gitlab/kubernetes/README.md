# Connecting GitLab to a Kubernetes Cluster

This exercise demonstrates how GitLab's agent server for Kubernetes can be used to connect a GitLab instance to a Kubernetes cluster. This setup allows both CI pipelines and GitLab users to interact with the cluster, enabling features like deploying applications, managing resources, and monitoring.

## Lessons Learned

For a few previous exercises, I had set up a Kubernetes cluster and deployed GitLab to it configured to use plain-HTTP. This approach worked for everything I had used at the time, but I ran into issues when trying to use some of the features that GitLab's kubernetes agent server provides. I ended up switching to a self-signed TLS certificate for the GitLab instance, which resolved one of the issues I was having.

Another issue relates to the GitLab command line client that can be used to authenticate and proxy requests to the Kubernetes cluster. I found that the client would generate personal access tokens set to expiration dates in the past if the request came to late in the day. This was due to the fact that the GitLab instance was set to use UTC time, while my local machine was set to a different timezone. I resolved this by setting the `TZ` environment variable to `UTC` before running the command, which ensured that the token was generated with the correct expiration date. A [merge request][MR] was submitted to the GitLab project to update the documentation to include this information.

<!-- Links -->

[MR]: https://gitlab.com/gitlab-org/cli/-/merge_requests/2114
