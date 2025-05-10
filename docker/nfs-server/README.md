# Running an NFS server in Docker

This exercise demonstrates how an NFS server can be run in a Docker container.

## Context

I have been evaluating storage class solutions for Kubernetes and
wanted to test NFS. While I could configure a full NFS server, I wanted
an easily replicable solution that I could semi-isolate in a container.

## Lessons Learned

Since NFS is implemented as part of the kernel, it is critical to use a
docker image that roughly aligns with the kernel version of the host. I
used too old an image initially and caused a rapid memory leak that
crashed my system within a few minutes of starting the container.

<!-- Links -->

https://hub.docker.com/r/mekayelanik/nfs-server-alpine
