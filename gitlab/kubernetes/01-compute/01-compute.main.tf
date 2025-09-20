## Required Providers

terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.5.0"
    }
  }
}

## Resources

resource "docker_container" "k3s" {
  name        = "gitlab-k3s"
  image       = "rancher/k3s:v1.33.4-k3s1"
  restart     = "unless-stopped"
  stop_signal = "SIGKILL"
  privileged  = true

  # wait for the cluster to be ready before considering the resource as
  # created to allow subsequent terragrunt modules to interact with the
  # cluster immediately
  wait = true

  entrypoint = ["sh", "-c"]

  command = [
    join(" ", [
      "/bin/k3s",
      "server",
      "--disable=traefik",
      "--disable=servicelb",
      "--disable=metrics-server",
      "--node-name=gitlab-k3s",
    ])
  ]

  tmpfs = {
    "/run"     = "",
    "/var/run" = "",
  }

  env = [
    "K3S_TOKEN=example",
    "K3S_KUBECONFIG_OUTPUT=/output/kubeconfig.yaml",
    "K3S_KUBECONFIG_MODE=666",
  ]

  ports {
    # Kubernetes API Server
    internal = 6443
    external = 6443
  }

  ports {
    # GitLab HTTP
    internal = 30080
    external = 80
  }

  ports {
    # GitLab HTTPS
    internal = 30443
    external = 443
  }

  ports {
    # GitLab SSH
    internal = 30022
    external = 2222
  }

  volumes {
    host_path      = dirname(abspath(path.module))
    container_path = "/output"
  }

  ulimit {
    name = "nproc"
    soft = 65535
    hard = 65535
  }

  healthcheck {
    test     = ["CMD-SHELL", "kubectl get nodes"]
    interval = "1s"
    timeout  = "1s"
    retries  = 15
  }
}
