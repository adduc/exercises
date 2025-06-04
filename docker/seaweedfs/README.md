# S3-compatible storage using SeaweedFS

This exercise demonstrates a SeaweedFS setup that provides S3-compatible storage.

## Context

With MinIO recently removing most of its management frontend from the open-source version, I wanted to explore what other solutions had developed in the S3-compatible storage space. SeaweedFS was one of the options I kept seeing recommended, so I decided to give it a try.

## Thoughts

I appreciate that SeaweedFS can be run in low memory environments and ships everything in a single binary. I had to go through a bit of research into the project's issues to find a way to speed up its boot time, but after that it seems to work well.
