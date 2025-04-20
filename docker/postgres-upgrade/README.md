# Upgrading Docker-based PostgreSQL from 15 to 16

This exercise demonstrates how a docker-based PostgreSQL instance can
be upgraded from version 15 to version 16. The process involves
stopping the existing PostgreSQL 15 instance, using a third-party
Docker image to perform the upgrade, and then starting a new PostgreSQL
16 instance.

## Context

While I have used PostgreSQL previously, I have not yet had to deal
with upgrading a PostgreSQL instance. With this exercise, I set out to
figure out how to perform the upgrade process entirely within Docker
containers.

## Configuration

A `.env` file is used to define the environment variables for the
PostgreSQL instances. An example `.dist.env` file is provided in the
repository, which you can copy and modify as needed.

## Starting the PostgreSQL 15 instance

```bash
docker compose up -d pg15
```

## Upgrading to PostgreSQL 16

PostgreSQL provides a utility called `pg_upgrade` that allows you to
upgrade your database cluster from one major version to another. It
requires both the old and new versions of PostgreSQL to be installed
and accessible. Since the official PostgreSQL Docker images do not
include both versions in a single container, we will use the
third-party image `pgautoupgrade/pgautoupgrade` to perform the upgrade.

```bash
docker compose stop pg15
docker compose up pgupgrade
```

The pgupgrade container will execute the `pg_upgrade` command to
perform the upgrade. The process may take some time, depending on the
size of your database. After the upgrade is complete, the container
will stop (depending on if PGAUTO_ONESHOT is set to yes or no).

## Starting the PostgreSQL 16 instance

```bash
docker compose up -d pg16
```
