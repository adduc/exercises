# Using an apt cache to speed up docker builds and ansible runs

This exercise demonstrates using an apt-cacher-ng container to cache apt packages.

## Context

I am looking into testing some ansible playbooks as part of a CI/CD pipeline. To speed up the process, I want to cache the apt packages that are downloaded when running the playbooks.

## Usage

The `docker-compose.yml` file defines a service for `apt-cacher-ng`, which is an apt caching proxy. The service listens on port 3142.

To use the apt-cacher-ng service, you can run the following command:

```bash
docker-compose up -d
```

This will start the apt-cacher-ng service in detached mode (i.e. in the background).

You can then configure your system to use the apt-cacher-ng service as a proxy for apt package downloads. This can be done by adding the following lines to your `/etc/apt/apt.conf.d/01proxy` file:

```bash
Acquire::HTTP::Proxy "http://172.17.0.1:3142";
Acquire::HTTPS::Proxy "false";
```

You can also access the apt-cacher-ng web interface by navigating to `http://localhost:3142/acng-report.html` in your web browser. This interface provides information about cached packages and statistics. It also allows you to run maintenance tasks such as cleaning the cache.

## Using as part of a Dockerfile

You can use the apt-cacher-ng service in your Dockerfile by adding the following lines:

```dockerfile

# RUN echo 'Acquire::HTTP::Proxy "http://172.17.0.1:3142";' >> /etc/apt/apt.conf.d/01proxy \
#  && echo 'Acquire::HTTPS::Proxy "false";' >> /etc/apt/apt.conf.d/01proxy

```

Assuming the apt-cacher-ng service is running on the host machine, this will configure the Docker container to use the apt-cacher-ng service as a proxy for apt package downloads.
