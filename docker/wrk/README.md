# Running wrk in Docker

Wrk is an HTTP benchmarking tool useful for testing the performance of web servers. I've loved using it for years, but recently it's become a bit of a hassle to build and install. Luckily, someone has created a Docker image that makes it easy to run wrk.

## Usage

```sh
docker compose run --rm wrk -c 10 -t 4 -d 10 http://127.0.0.1
```