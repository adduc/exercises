# Disabling request body processing for GET requests in NGINX

This exercise demonstrates how request body processing can be
conditionally disabled for GET requests in NGINX. This can be useful when working with applications that incorrectly process GET requests with a body.

## Context

I am working on a Laravel project and have noticed it prioritizes
processing GET request bodies over query parameters, which could lead
to cache poisoning and other unexpected behavior. I wanted to try to
disable request body processing for GET requests in NGINX to mitigate
these issues.
