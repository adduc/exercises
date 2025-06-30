# Running Ollama in Kubernetes

This exercise demonstrates deploying Ollama's helm chart using
Terraform.

## Context

I recently worked with a client interested in running self-hosted LLMs.
While I had previously run Ollama through Docker, I wanted to explore
running it in Kubernetes where resources could be more easily managed
and scaled.

## Lessons Learned

Once up and running, there was no discernible performance difference
between running Ollama in Docker or Kubernetes.
