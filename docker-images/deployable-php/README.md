# Docker image to test PHP-based deployments

This image provides a simple PHP environment that can be used to test deployment scripts and configurations. It is designed to be used with deployer, a popular deployment tool for PHP applications.

## Features

- PHP 8.4
- rsync
- openssh server

## Context

I recently worked with a client who had a PHP-based application that was deployed using deployer. To make it easier to test changes to the deployment process, I wanted to create a Docker image that could act as a stand-in for the production environment.
