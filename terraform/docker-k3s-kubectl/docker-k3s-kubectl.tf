## Terraform Configuration

terraform {
  required_providers {

    # @see https://github.com/kreuzwerker/terraform-provider-docker/releases
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.6.2"
    }

    # @see https://github.com/adduc/terraform-provider-docker/releases
    jlong-docker = {
      source  = "registry.terraform.io/adduc/docker"
      version = "0.0.3"
    }

    # @see https://github.com/alekc/terraform-provider-kubectl
    kubectl = {
      source  = "alekc/kubectl"
      version = "2.1.3"
    }

  }
}

## Provider Configuration

locals {
  kubeconfig = yamldecode(data.docker_file.kubeconfig.file.content)
}

# @see https://registry.terraform.io/providers/kreuzwerker/docker/latest
provider "docker" {}

# @see https://registry.terraform.io/providers/adduc/docker/latest
provider "jlong-docker" {}

# @see https://registry.terraform.io/providers/alekc/kubectl/latest
provider "kubectl" {
  host                   = "127.0.0.1:${docker_container.k3s.ports[0].external}"
  cluster_ca_certificate = base64decode(local.kubeconfig["clusters"][0]["cluster"]["certificate-authority-data"])
  client_key             = base64decode(local.kubeconfig["users"][0]["user"]["client-key-data"])
  client_certificate     = base64decode(local.kubeconfig["users"][0]["user"]["client-certificate-data"])
}

## Resources / Data Sources

resource "docker_container" "k3s" {
  name       = "k3s"
  image      = "rancher/k3s:v1.32.1-k3s1"
  restart    = "unless-stopped"
  privileged = true

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
        "--node-name=k3s",
      ])
    ])
  ]

  tmpfs = {
    "/run"     = "",
    "/var/run" = "",
  }

  env = [
    "K3S_TOKEN=asdfasdf",
  ]

  ports {
    # Kubernetes API Server
    internal = 6443
    external = 6443
  }

  volumes {
    host_path      = "${abspath(path.module)}/data/k3s-server"
    container_path = "/var/lib/rancher/k3s"
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

data "docker_file" "kubeconfig" {
  provider   = jlong-docker
  depends_on = [docker_container.k3s]
  container  = docker_container.k3s.id
  path       = "/etc/rancher/k3s/k3s.yaml"
}

resource "kubectl_manifest" "deployment" {
  depends_on = [docker_container.k3s]
  yaml_body = yamlencode({
    apiVersion = "apps/v1"
    kind       = "Deployment"
    metadata = {
      name = "example-app"
    }
    spec = {
      replicas = 1
      selector = {
        matchLabels = {
          app = "example-app"
        }
      }
      template = {
        metadata = {
          labels = {
            app = "example-app"
          }
        }
        spec = {
          containers = [
            {
              name  = "example-container"
              image = "nginx:latest"
              ports = [
                {
                  containerPort = 80
                }
              ]
            }
          ]
        }
      }
    }
  })
}
