# ReactPHP Server

This exercise demonstrates how ReactPHP can be used to create a simple HTTP server. The server has two endpoints: `/` and `/metrics`. The `/` endpoint returns a simple HTML page, while the `/metrics` endpoint returns a sample counter in OpenMetrics format. All other requests return a 404 error.

```sh
# Install dependencies
composer install
# Start the server
php server.php

# Start the server with JIT enabled
php -d opcache.jit=1 server.php
```
