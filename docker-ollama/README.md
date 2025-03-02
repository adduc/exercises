# Running Ollama within Docker

This exercise shows how Ollama can be run entirely within a Docker container. This is useful to keep your local environment clean and to ensure that all dependencies are contained within the Docker image.

## Context

In the past, I have had issues running Ollama with AMD GPUs. I would like like to run Ollama using their Docker image to easily test new versions at a whim without needing to manage dependencies on my local machine.

## Usage

```sh

# Run the Ollama server
docker compose up -d

# Run the Ollama CLI (in this case, the `phi4` model)
docker compose exec -it ollama ollama run phi4
```