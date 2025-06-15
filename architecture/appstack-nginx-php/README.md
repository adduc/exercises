# App stack: Nginx + PHP

This exercise demonstrates the use of `Adduc` docker images to run a
web application stack with Nginx and PHP. The stack is designed to be
lightweight and ready for demonstration purposes.

## Usage

A `docker-compose.yml` file is provided to simplify the process of
running the application stack. You can start the stack by running:

```bash
docker-compose up -d
```

This command will start the Nginx and PHP containers in detached mode.
To stop the stack, you can run:

```bash
docker-compose down
```

## Installation

- `cp .env .env.example`: This command copies the example environment file to a new `.env` file. You can modify this file to set your application configuration, such as database connection details.
- `composer install`: composer is not installed in the image, so you need to run this command on your host machine or mount a volume with your local composer installation.
- `php artisan migrate`: this command will run the database migrations. Make sure your database is set up correctly in the `.env` file.

