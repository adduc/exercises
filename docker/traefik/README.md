# Running Traefik within Docker

This exercise shows how Traefik can be run within Docker to provide a reverse proxy for other services. While it supports a variety of providers, this example uses a file-based configuration for simplicity.

## Context

A few of my projects are at the point where I want to begin serving them on a remote server. I have experience with Nginx, but want to try using Traefik as it has built-in support for Let's Encrypt and automatic SSL certificate generation.

## Notes

- Traefik has some potential performance improvements in [3.2.0](https://github.com/traefik/traefik/releases/tag/v3.2.0)
  - The [blog post for the release](https://traefik.io/blog/traefik-proxy-v3-2-a-munster-release/) indicates how to enable the new experimental `fastProxy` feature.
