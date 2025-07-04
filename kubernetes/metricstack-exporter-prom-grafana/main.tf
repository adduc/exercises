##
# This example shows a "metric stack" deployment on Kubernetes using Helm.
#
# It deploys Nginx Gateway Fabric, Prometheus, Node Exporter,
# Blackbox Exporter, and Grafana.
##

## Inputs

## Required Providers

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.0"
    }
  }
}

## Provider Configuration

provider "helm" {
  kubernetes {
    config_path = "${path.module}/kubeconfig.yaml"
  }
}

provider "kubectl" {
  config_path = "${path.module}/kubeconfig.yaml"
}

## Resources

##
# Gateway API CRDs deploy using Helm
# - Required for Nginx Gateway Fabric
# @see https://artifacthub.io/packages/helm/portefaix-hub/gateway-api-crds
##
resource "helm_release" "gateway-api" {
  name       = "gateway-api"
  repository = "https://charts.portefaix.xyz/"
  chart      = "gateway-api-crds"
  version    = "1.2.1"
}

##
# Nginx Gateway Fabric deploy using Helm
# @see https://docs.nginx.com/nginx-gateway-fabric/installation/installing-ngf/helm/
# @see https://github.com/nginx/nginx-gateway-fabric/pkgs/container/charts%2Fnginx-gateway-fabric
# Compatibility matrix between Nginx Gateway Fabric and Gateway API versions
# @see https://github.com/nginx/nginx-gateway-fabric/blob/v1.5.1/README.md#technical-specifications
##
resource "helm_release" "nginx-gateway-fabric" {
  depends_on = [helm_release.gateway-api]
  name       = "nginx-gateway-fabric"
  repository = "oci://ghcr.io/nginx/charts"
  chart      = "nginx-gateway-fabric"
  version    = "2.0.1"

  values = [
    # @see https://github.com/nginx/nginx-gateway-fabric/blob/main/charts/nginx-gateway-fabric/values.yaml
    yamlencode({
      nginx = {
        service = {
          type = "NodePort"

          nodePorts = [
            {
              port         = 30080 # external port
              listenerPort = 80    # service port for internal traffic
            }
          ]
        }
      }
    })
  ]
}

##
# Default gateway for our services
#
# This gateway resource represents traffic to Nginx Gateway Fabric
# on port 80. It will be used by http routes to inform Nginx Gateway
# Fabric how and where to route traffic.
##
resource "kubectl_manifest" "gateway" {
  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata = {
      name = "nginx-gateway"
    }
    spec = {
      gatewayClassName = "nginx"
      listeners = [
        {
          name     = "http"
          protocol = "HTTP"
          port     = 80
        }
      ]
    }
  })

  depends_on = [
    helm_release.gateway-api
  ]
}

##
# Blackbox Exporter: A Prometheus exporter to probe endpoints over
# HTTP, HTTPS, DNS, TCP, ICMP, and more.
#
# @see https://github.com/prometheus/blackbox_exporter
# @see https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus-blackbox-exporter
##
resource "helm_release" "blackbox_exporter" {
  name       = "blackbox-exporter"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-blackbox-exporter"
  version    = "11.0.0"

  values = [
    # @see https://github.com/prometheus-community/helm-charts/blob/main/charts/prometheus-blackbox-exporter/values.yaml
    yamlencode({
      fullnameOverride = "blackbox"

      config = {
        # This is the default module list, but we can customize it as
        # needed (e.g. to add a module to test DNS, or TCP connections).
        modules = {
          http_2xx = {
            prober  = "http"
            timeout = "5s"
            http = {
              valid_http_versions   = ["HTTP/1.1", "HTTP/2.0"]
              follow_redirects      = true
              preferred_ip_protocol = "ip4"
            }
          }
        }
      }
    })
  ]
}

##
# Prometheus: A powerful open-source monitoring and alerting toolkit.
# @see https://prometheus.io/
# @see https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus
##
resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  version    = "27.20.0"

  # @see https://github.com/prometheus-community/helm-charts/blob/main/charts/prometheus/values.yaml
  values = [
    yamlencode({
      prometheus-pushgateway = {
        enabled = false
      }

      kube-state-metrics = {
        enabled = false
      }

      extraScrapeConfigs = yamlencode(
        [
          # alertmanager
          {
            job_name     = "alertmanager"
            metrics_path = "/metrics"
            static_configs = [{
              targets = ["prometheus-alertmanager:9093"]
            }]
          },

          # blackbox exporter
          {
            job_name     = "blackbox-exporter"
            metrics_path = "/probe"
            params = {
              module = ["http_2xx"]
            }
            # List of endpoints to probe
            static_configs = [{
              targets = ["https://example.com"]
            }]
            relabel_configs = [
              {
                source_labels = ["__address__"]
                target_label  = "__param_target"
              },
              {
                source_labels = ["__param_target"]
                target_label  = "instance"
              },

              # This relabel is required, and tells Prometheus to send
              # the request for each target to the blackbox exporter
              # service, which will then probe the target.
              {
                target_label = "__address__"
                replacement  = "blackbox:9115"
              },
            ]
          },
        ]
      ),

      serverFiles = {
        "alerting_rules.yml" = {
          groups = [
            {
              name = "ssl_cert_expiration"
              rules = [
                # warn if SSL certificate expires in less than 30 days
                {
                  alert = "SSLExpiration"
                  expr  = "(probe_ssl_earliest_cert_expiry{job=\"blackbox-exporter\"} - time()) / (60 * 60 * 24) < 30"
                  for   = "5m"
                  labels = {
                    severity = "warning"
                    team     = "platform"
                  }
                },
                # critical if SSL certificate expires in less than 7 days
                {
                  alert = "SSLExpirationCritical"
                  expr  = "(probe_ssl_earliest_cert_expiry{job=\"blackbox-exporter\"} - time()) / (60 * 60 * 24) < 7"
                  for   = "5m"
                  labels = {
                    severity = "critical"
                    team     = "platform"
                  }
                }
              ]
            },

            # node exporter
            {
              name = "cpu_usage"
              rules = [
                # warn if node CPU usage is above 80% for 5 minutes
                {
                  alert = "NodeHighCPUUsage"
                  expr  = "100 - (avg by (instance) (rate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100) > 80"
                  for   = "5m"
                  labels = {
                    severity = "warning"
                    team     = "platform"
                  }
                },
                # critical if node CPU usage is above 90% for 5 minutes
                {
                  alert = "NodeCriticalCPUUsage"
                  expr  = "100 - (avg by (instance) (rate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100) > 90"
                  for   = "5m"
                  labels = {
                    severity = "critical"
                    team     = "platform"
                  }
                }
              ]
            },
            {
              name = "memory_usage"
              rules = [
                # warn if node memory usage is above 80% for 5 minutes
                {
                  alert = "NodeHighMemoryUsage"
                  expr  = "1 - (node_memory_MemFree_bytes / node_memory_MemTotal_bytes) > 0.8"
                  for   = "5m"
                  labels = {
                    severity = "warning"
                    team     = "platform"
                  }
                },
                # critical if node memory usage is above 90% for 5 minutes
                {
                  alert = "NodeCriticalMemoryUsage"
                  expr  = "1 - (node_memory_MemFree_bytes / node_memory_MemTotal_bytes) > 0.9"
                  for   = "5m"
                  labels = {
                    severity = "critical"
                    team     = "platform"
                  }
                }
              ]
            }
          ]
        }
      }
    })
  ]
}

##
# Http Route for Prometheus
#
# This route will direct traffic to the Prometheus server based on the
# host header.
##
resource "kubectl_manifest" "http_route_prometheus" {
  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name = "prometheus"
    }
    spec = {
      parentRefs = [{ name = "nginx-gateway" }]
      rules = [{
        matches = [{
          headers = [{
            name  = "Host"
            type  = "RegularExpression"
            value = "prometheus\\..+"
          }]
        }]
        backendRefs = [{
          name = "prometheus-server"
          port = 80
        }]
      }]
    }
  })

  depends_on = [
    helm_release.gateway-api
  ]
}

##
# Http Route for Alertmanager (installed with the Prometheus Helm chart)
#
# This route will direct traffic to the Alertmanager server based on the
# host header.
##
resource "kubectl_manifest" "http_route_alertmanager" {
  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name = "alertmanager"
    }
    spec = {
      parentRefs = [{ name = "nginx-gateway" }]
      rules = [{
        matches = [{
          headers = [{
            name  = "Host"
            type  = "RegularExpression"
            value = "alertmanager\\..+"
          }]
        }]
        backendRefs = [{
          name = "prometheus-alertmanager"
          port = 9093
        }]
      }]
    }
  })

  depends_on = [
    helm_release.gateway-api
  ]
}

##
# Grafana: visualization platform for observability and data analytics
#
# @see https://grafana.com/
# @see https://github.com/grafana/helm-charts/tree/main/charts/grafana
##
resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts/"
  chart      = "grafana"
  version    = "9.2.7"

  values = [
    # @see https://github.com/grafana/helm-charts/blob/main/charts/grafana/values.yaml
    yamlencode({
      adminUser     = "admin"
      adminPassword = "admin"

      ## Configure grafana datasources
      ## ref: http://docs.grafana.org/administration/provisioning/#datasources
      ##
      datasources = {
        "datasources.yaml" = {
          apiVersion = 1
          datasources = [
            {
              name      = "Prometheus"
              type      = "prometheus"
              url       = "http://prometheus-server"
              access    = "proxy"
              isDefault = true
            },
          ]
        }
      }

      dashboardProviders = {
        "dashboardproviders.yaml" = {
          apiVersion = 1
          providers = [
            {
              name            = "default"
              orgId           = 1
              folder          = ""
              type            = "file"
              disableDeletion = false
              editable        = true
              options         = { path = "/var/lib/grafana/dashboards/default" }
            }
          ]
        }
      }

      dashboards = {
        default = {
          # @see https://grafana.com/grafana/dashboards/1860-node-exporter-full/
          node_exporter = {
            gnetId     = 1860
            revision   = 41
            datasource = "Prometheus"
          },
          # @see https://grafana.com/grafana/dashboards/9578-alertmanager/
          alert_manager = {
            gnetId     = 9578
            revision   = 4
            datasource = "Prometheus"
          },

          # @see https://grafana.com/grafana/dashboards/13659-blackbox-exporter-http-prober/
          blackbox_exporter = {
            gnetId     = 13659
            revision   = 1
            datasource = "Prometheus"
          },
        }
      }

      persistence = {
        enabled = true
      }
    })
  ]
}

##
# Http Route for Grafana
#
# This route will direct traffic to the Grafana server based on the
# host header.
##
resource "kubectl_manifest" "http_route_grafana" {
  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name = "grafana"
    }
    spec = {
      parentRefs = [{ name = "nginx-gateway" }]
      rules = [{
        matches = [{
          headers = [{
            name  = "Host"
            type  = "RegularExpression"
            value = "grafana\\..+"
          }]
        }]
        backendRefs = [{
          name = "grafana"
          port = 80
        }]
      }]
    }
  })

  depends_on = [
    helm_release.gateway-api
  ]
}
