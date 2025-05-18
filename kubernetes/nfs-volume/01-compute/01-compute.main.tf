## Terraform configuration

terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.5.0"
    }
  }
}

## Provider configuration

provider "docker" {}

## Input Variables

variable "env_name" { default = "nfs-volume" }
variable "k3s_image" { default = "rancher/k3s" }

variable "k3s_version" {
  # @see https://github.com/k3s-io/k3s/releases
  type    = string
  default = "v1.33.0-k3s1"
}

variable "k3s_token" { default = "changeme" }

variable "keep_images_on_destroy" {
  description = <<-EOT
    When destroying docker_image resources, whether to delete the image
    from the provider's cache. This may be useful during development
    to avoid re-downloading the image every time.
  EOT
  type        = bool
  default     = true
}

## Resources

resource "docker_image" "k3s" {
  name         = "${var.k3s_image}:${var.k3s_version}"
  keep_locally = var.keep_images_on_destroy
}

resource "docker_network" "k3s" {
  name = "${var.env_name}-k3s"
}

resource "docker_container" "k3s" {
  name         = "${var.env_name}-k3s"
  image        = docker_image.k3s.image_id
  restart      = "unless-stopped"
  stop_signal  = "SIGKILL"
  privileged   = true
  network_mode = docker_network.k3s.name

  # wait for the cluster to be ready before considering the resource as
  # created to allow subsequent terragrunt modules to interact with the
  # cluster immediately
  wait = true

  entrypoint = ["sh", "-c"]

  command = [
    join(" && ", [
      # Workaround for `path "/var/lib/kubelet/pods" is mounted on
      # "/var/lib/kubelet" but it is not a shared mount`
      # @see https://github.com/k3d-io/k3d/issues/1063#issuecomment-1153271637
      "mount --make-rshared /",
      join(" ", [
        "/bin/k3s",
        "server",
        "--disable=traefik",
        "--disable=servicelb",
        "--disable=metrics-server",
        "--node-name=${var.env_name}",
      ])
    ])
  ]

  tmpfs = {
    "/run"     = "",
    "/var/run" = "",
  }

  env = [
    "K3S_TOKEN=${var.k3s_token}",
    "K3S_KUBECONFIG_OUTPUT=/output/kubeconfig.yaml",
    "K3S_KUBECONFIG_MODE=666",
  ]

  # Docker's iptables rules are configured in a way that will route
  # DNS traffic for the container accurately, but not for pods within
  # k3s. Instead of modifying the iptables rules, we can manually set
  # a hosts entry to allow resolving the NFS server from within k3s
  host {
    host = docker_container.nfs.name
    ip   = docker_container.nfs.network_data[0].ip_address
  }

  ports {
    # Kubernetes API Server
    internal = 6443
    external = 6443
  }

  ports {
    # Example NodePort (e.g. for a service)
    internal = 30080
    external = 80
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

resource "docker_container" "nfs" {
  name         = "${var.env_name}-nfs"
  image        = "mekayelanik/nfs-server-alpine:latest"
  restart      = "unless-stopped"
  network_mode = docker_network.k3s.name

  volumes {
    host_path      = "${dirname(abspath(path.module))}/data"
    container_path = "/data"
  }

  volumes {
    host_path      = "/lib/modules"
    container_path = "/lib/modules"
    read_only      = true
  }

  capabilities {
    add = ["CAP_SYS_ADMIN", "CAP_SETPCAP", "CAP_SYS_MODULE"]
  }

  env = [
    "ALLOWED_CLIENT=*",
  ]
}
