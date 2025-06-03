# Deploying a PHP codebase using Deployer

This exercise demonstrates how Deployer can be used to deploy a PHP codebase to a server. In this implementation, rsync is used to transfer files.

## Usage

This exercise depends on a server that can be accessed via SSH and has
PHP installed. An example server is available in
`../docker-images/deployable-php`.

## Context

I recently worked with a client who had a PHP-based application that was deployed using deployer. To better understand how Deployer works, I wanted to create a simple example that could be used to deploy a PHP codebase.
