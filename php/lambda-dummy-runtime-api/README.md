# Exercise: A dummy implementation of AWS' Lambda Runtime API

## Context

I was building some lambdas from scratch instead of using AWS'
libraries. To allow for faster iteration, I wanted to be able to run
the lambdas locally instead of deploying them to AWS between each invocation.

## Requirements

- PHP
- Make

## Usage

A Makefile is provided to help you get started.

To run the server:

```sh
make serve
```

The server will be available at `http://localhost:9001`.

This can be passed to the lambda client as the `AWS_LAMBDA_RUNTIME_API`
environment variable. As an example:

```sh
env AWS_LAMBDA_RUNTIME_API=localhost:9001 ./lambda
```