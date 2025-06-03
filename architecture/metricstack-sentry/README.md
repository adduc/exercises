# Profiling a Laravel application using self-hosted Sentry

This exercise demonstrates how sentry can be provisioned locally and used to profile a Laravel application.

## Usage

A Makefile is provided to simplify the process of installing sentry. To install sentry, run:

```bash
make sentry/install
```

This will run sentry's self-hosted installation script, which will take
a few minutes to complete. After the installation script completes,
profiling functionality is enabled and an example Sentry user is
created.
