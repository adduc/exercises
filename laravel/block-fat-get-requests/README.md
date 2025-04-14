# Blocking "fat" GET requests in Laravel through middleware

This exercise shows how middleware can be used to intercept and manage incoming requests, ensuring that GET requests with request bodies are blocked to maintain the integrity of the application.

## Context

I have been working on a project with publicly accessible endpoints. While testing request validation and pagination, I noticed that Laravel will prioritize request bodies over query parameters in a lot of its built-in functionality. This could lead to cache poisoning and unexpected behavior. To avoid these types of foot-guns, I wanted to block all GET requests to the project that contain a request body.
