##
# vSphere CSI Driver
#
# @see https://kubernetes-sigs.github.io/vsphere-csi-driver/
##

## Terraform Configuration

terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    tls = {
      source = "hashicorp/tls"
    }
  }
}

variable "vsphere" {
  description = "vSphere credentials and cluster topology used to configure the CSI driver."
  type = object({
    user                 = string
    password             = string
    vsphere_server       = string
    allow_unverified_ssl = bool
    datacenter           = string
    datastore_url        = string
    cluster_id           = string
  })
}

## Namespace

resource "kubernetes_namespace" "vmware_system_csi" {
  metadata {
    name = "vmware-system-csi"
  }
}

## Secrets

resource "kubernetes_secret" "vsphere_config" {
  metadata {
    name      = "vsphere-config-secret"
    namespace = kubernetes_namespace.vmware_system_csi.metadata[0].name
  }

  data = {
    "csi-vsphere.conf" = <<-EOT
      [Global]
      cluster-id = "${var.vsphere.cluster_id}"

      [VirtualCenter "${var.vsphere.vsphere_server}"]
      insecure-flag = "${var.vsphere.allow_unverified_ssl}"
      user = "${var.vsphere.user}"
      password = "${var.vsphere.password}"
      port = "443"
      datacenters = "${var.vsphere.datacenter}"
    EOT
  }
}

## Webhook TLS

resource "tls_private_key" "webhook_ca" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "webhook_ca" {
  private_key_pem = tls_private_key.webhook_ca.private_key_pem

  subject {
    common_name = "vSphere CSI Admission Controller Webhook CA"
  }

  validity_period_hours = 8760
  is_ca_certificate     = true
  allowed_uses          = ["cert_signing", "crl_signing"]
}

resource "tls_private_key" "webhook_server" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "webhook_server" {
  private_key_pem = tls_private_key.webhook_server.private_key_pem

  subject {
    common_name = "vsphere-webhook-svc.vmware-system-csi.svc"
  }

  dns_names = [
    "vsphere-webhook-svc",
    "vsphere-webhook-svc.vmware-system-csi",
    "vsphere-webhook-svc.vmware-system-csi.svc",
  ]
}

resource "tls_locally_signed_cert" "webhook_server" {
  cert_request_pem      = tls_cert_request.webhook_server.cert_request_pem
  ca_private_key_pem    = tls_private_key.webhook_ca.private_key_pem
  ca_cert_pem           = tls_self_signed_cert.webhook_ca.cert_pem
  validity_period_hours = 8759

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
  ]
}

resource "kubernetes_secret" "vsphere_webhook_certs" {
  metadata {
    name      = "vsphere-webhook-certs"
    namespace = kubernetes_namespace.vmware_system_csi.metadata[0].name
  }

  data = {
    "tls.key"        = tls_private_key.webhook_server.private_key_pem
    "tls.crt"        = tls_locally_signed_cert.webhook_server.cert_pem
    "webhook.config" = "[WebHookConfig]\nport = \"8443\"\ncert-file = \"/run/secrets/tls/tls.crt\"\nkey-file = \"/run/secrets/tls/tls.key\"\n"
  }
}

## CSIDriver

resource "kubernetes_manifest" "csi_driver" {
  manifest = {
    apiVersion = "storage.k8s.io/v1"
    kind       = "CSIDriver"
    metadata = {
      name = "csi.vsphere.vmware.com"
    }
    spec = {
      attachRequired = true
      podInfoOnMount = false
    }
  }
}

## Service Accounts

resource "kubernetes_service_account" "csi_controller" {
  metadata {
    name      = "vsphere-csi-controller"
    namespace = kubernetes_namespace.vmware_system_csi.metadata[0].name
  }
}

resource "kubernetes_service_account" "csi_node" {
  metadata {
    name      = "vsphere-csi-node"
    namespace = kubernetes_namespace.vmware_system_csi.metadata[0].name
  }
}

resource "kubernetes_service_account" "csi_webhook" {
  metadata {
    name      = "vsphere-csi-webhook"
    namespace = kubernetes_namespace.vmware_system_csi.metadata[0].name
  }
}

## RBAC — Controller

resource "kubernetes_cluster_role" "csi_controller" {
  metadata {
    name = "vsphere-csi-controller-role"
  }

  rule {
    api_groups = [""]
    resources  = ["nodes", "pods"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    api_groups = [""]
    resources  = ["configmaps"]
    verbs      = ["get", "list", "watch", "create"]
  }
  rule {
    api_groups = [""]
    resources  = ["persistentvolumeclaims"]
    verbs      = ["get", "list", "watch", "update"]
  }
  rule {
    api_groups = [""]
    resources  = ["persistentvolumeclaims/status"]
    verbs      = ["patch"]
  }
  rule {
    api_groups = [""]
    resources  = ["persistentvolumes"]
    verbs      = ["get", "list", "watch", "create", "update", "delete", "patch"]
  }
  rule {
    api_groups = [""]
    resources  = ["events"]
    verbs      = ["get", "list", "watch", "create", "update", "patch"]
  }
  rule {
    api_groups = ["coordination.k8s.io"]
    resources  = ["leases"]
    verbs      = ["get", "watch", "list", "delete", "update", "create"]
  }
  rule {
    api_groups = ["storage.k8s.io"]
    resources  = ["storageclasses", "csinodes"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    api_groups = ["storage.k8s.io"]
    resources  = ["volumeattachments"]
    verbs      = ["get", "list", "watch", "patch"]
  }
  rule {
    api_groups = ["storage.k8s.io"]
    resources  = ["volumeattachments/status"]
    verbs      = ["patch"]
  }
  rule {
    api_groups = ["cns.vmware.com"]
    resources  = ["triggercsifullsyncs"]
    verbs      = ["create", "get", "update", "watch", "list"]
  }
  rule {
    api_groups = ["cns.vmware.com"]
    resources  = ["cnsvspherevolumemigrations"]
    verbs      = ["create", "get", "list", "watch", "update", "delete"]
  }
  rule {
    api_groups = ["cns.vmware.com"]
    resources  = ["cnsvolumeinfoes"]
    verbs      = ["create", "get", "list", "watch", "delete"]
  }
  rule {
    api_groups = ["cns.vmware.com"]
    resources  = ["cnsvolumeoperationrequests"]
    verbs      = ["create", "get", "list", "update", "delete"]
  }
  rule {
    api_groups = ["cns.vmware.com"]
    resources  = ["csinodetopologies"]
    verbs      = ["get", "update", "watch", "list"]
  }
  rule {
    api_groups = ["apiextensions.k8s.io"]
    resources  = ["customresourcedefinitions"]
    verbs      = ["get", "create", "update"]
  }
  rule {
    api_groups = ["snapshot.storage.k8s.io"]
    resources  = ["volumesnapshots"]
    verbs      = ["get", "list"]
  }
  rule {
    api_groups = ["snapshot.storage.k8s.io"]
    resources  = ["volumesnapshotclasses"]
    verbs      = ["watch", "get", "list"]
  }
  rule {
    api_groups = ["snapshot.storage.k8s.io"]
    resources  = ["volumesnapshotcontents"]
    verbs      = ["create", "get", "list", "watch", "update", "delete", "patch"]
  }
  rule {
    api_groups = ["snapshot.storage.k8s.io"]
    resources  = ["volumesnapshotcontents/status"]
    verbs      = ["update", "patch"]
  }
}

resource "kubernetes_cluster_role_binding" "csi_controller" {
  metadata {
    name = "vsphere-csi-controller-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.csi_controller.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.csi_controller.metadata[0].name
    namespace = kubernetes_namespace.vmware_system_csi.metadata[0].name
  }
}

## RBAC — Node

resource "kubernetes_cluster_role" "csi_node" {
  metadata {
    name = "vsphere-csi-node-cluster-role"
  }

  rule {
    api_groups = ["cns.vmware.com"]
    resources  = ["csinodetopologies"]
    verbs      = ["create", "watch", "get", "patch"]
  }
  rule {
    api_groups = [""]
    resources  = ["nodes"]
    verbs      = ["get"]
  }
}

resource "kubernetes_cluster_role_binding" "csi_node" {
  metadata {
    name = "vsphere-csi-node-cluster-role-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.csi_node.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.csi_node.metadata[0].name
    namespace = kubernetes_namespace.vmware_system_csi.metadata[0].name
  }
}

resource "kubernetes_role" "csi_node" {
  metadata {
    name      = "vsphere-csi-node-role"
    namespace = kubernetes_namespace.vmware_system_csi.metadata[0].name
  }

  rule {
    api_groups = [""]
    resources  = ["configmaps"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_role_binding" "csi_node" {
  metadata {
    name      = "vsphere-csi-node-binding"
    namespace = kubernetes_namespace.vmware_system_csi.metadata[0].name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.csi_node.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.csi_node.metadata[0].name
    namespace = kubernetes_namespace.vmware_system_csi.metadata[0].name
  }
}

## RBAC — Webhook

resource "kubernetes_cluster_role" "csi_webhook" {
  metadata {
    name = "vsphere-csi-webhook-cluster-role"
  }

  rule {
    api_groups = ["snapshot.storage.k8s.io"]
    resources  = ["volumesnapshots"]
    verbs      = ["get", "list"]
  }
  rule {
    api_groups = [""]
    resources  = ["persistentvolumes"]
    verbs      = ["get"]
  }
}

resource "kubernetes_cluster_role_binding" "csi_webhook" {
  metadata {
    name = "vsphere-csi-webhook-cluster-role-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.csi_webhook.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.csi_webhook.metadata[0].name
    namespace = kubernetes_namespace.vmware_system_csi.metadata[0].name
  }
}

resource "kubernetes_role" "csi_webhook" {
  metadata {
    name      = "vsphere-csi-webhook-role"
    namespace = kubernetes_namespace.vmware_system_csi.metadata[0].name
  }

  rule {
    api_groups = [""]
    resources  = ["configmaps"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_role_binding" "csi_webhook" {
  metadata {
    name      = "vsphere-csi-webhook-role-binding"
    namespace = kubernetes_namespace.vmware_system_csi.metadata[0].name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.csi_webhook.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.csi_webhook.metadata[0].name
    namespace = kubernetes_namespace.vmware_system_csi.metadata[0].name
  }
}

## ConfigMap

resource "kubernetes_config_map" "csi_feature_states" {
  metadata {
    name      = "internal-feature-states.csi.vsphere.vmware.com"
    namespace = kubernetes_namespace.vmware_system_csi.metadata[0].name
  }

  data = {
    "trigger-csi-fullsync"              = "false"
    "pv-to-backingdiskobjectid-mapping" = "false"
  }
}

## Services

resource "kubernetes_service" "csi_controller" {
  metadata {
    name      = "vsphere-csi-controller"
    namespace = kubernetes_namespace.vmware_system_csi.metadata[0].name
    labels = {
      app = "vsphere-csi-controller"
    }
  }

  spec {
    selector = {
      app = "vsphere-csi-controller"
    }

    port {
      name        = "ctlr"
      port        = 2112
      target_port = 2112
      protocol    = "TCP"
    }

    port {
      name        = "syncer"
      port        = 2113
      target_port = 2113
      protocol    = "TCP"
    }
  }
}

resource "kubernetes_service" "csi_webhook" {
  metadata {
    name      = "vsphere-webhook-svc"
    namespace = kubernetes_namespace.vmware_system_csi.metadata[0].name
    labels = {
      app = "vsphere-csi-webhook"
    }
  }

  spec {
    selector = {
      app = "vsphere-csi-webhook"
    }

    port {
      port        = 443
      target_port = 8443
    }
  }
}

## Controller Deployment

resource "kubernetes_deployment" "csi_controller" {
  depends_on = [
    kubernetes_secret.vsphere_config,
    kubernetes_config_map.csi_feature_states,
    kubernetes_service_account.csi_controller,
  ]

  metadata {
    name      = "vsphere-csi-controller"
    namespace = kubernetes_namespace.vmware_system_csi.metadata[0].name
  }

  spec {
    # Single-node k3s: podAntiAffinity prevents scheduling >1 replica on the same host
    replicas = 1

    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_unavailable = 1
        max_surge       = 0
      }
    }

    selector {
      match_labels = {
        app = "vsphere-csi-controller"
      }
    }

    template {
      metadata {
        labels = {
          app  = "vsphere-csi-controller"
          role = "vsphere-csi"
        }
      }

      spec {
        priority_class_name  = "system-cluster-critical"
        service_account_name = kubernetes_service_account.csi_controller.metadata[0].name
        dns_policy           = "Default"

        affinity {
          node_affinity {
            required_during_scheduling_ignored_during_execution {
              node_selector_term {
                match_expressions {
                  key      = "node-role.kubernetes.io/control-plane"
                  operator = "Exists"
                }
              }
              node_selector_term {
                match_expressions {
                  key      = "node-role.kubernetes.io/controlplane"
                  operator = "Exists"
                }
              }
              node_selector_term {
                match_expressions {
                  key      = "node-role.kubernetes.io/master"
                  operator = "Exists"
                }
              }
            }
          }
        }

        toleration {
          key      = "node-role.kubernetes.io/master"
          operator = "Exists"
          effect   = "NoSchedule"
        }

        toleration {
          key      = "node-role.kubernetes.io/control-plane"
          operator = "Exists"
          effect   = "NoSchedule"
        }

        volume {
          name = "vsphere-config-volume"
          secret {
            secret_name = kubernetes_secret.vsphere_config.metadata[0].name
          }
        }

        volume {
          name = "socket-dir"
          empty_dir {}
        }

        container {
          name  = "csi-attacher"
          image = "registry.k8s.io/sig-storage/csi-attacher:v4.9.0"

          args = [
            "--v=4",
            "--timeout=300s",
            "--csi-address=$(ADDRESS)",
            "--leader-election",
            "--leader-election-lease-duration=120s",
            "--leader-election-renew-deadline=60s",
            "--leader-election-retry-period=30s",
            "--kube-api-qps=100",
            "--kube-api-burst=100",
            "--worker-threads=100",
          ]

          env {
            name  = "ADDRESS"
            value = "/csi/csi.sock"
          }

          volume_mount {
            mount_path = "/csi"
            name       = "socket-dir"
          }
        }

        container {
          name  = "csi-resizer"
          image = "registry.k8s.io/sig-storage/csi-resizer:v1.12.0"

          args = [
            "--v=4",
            "--timeout=300s",
            "--handle-volume-inuse-error=false",
            "--csi-address=$(ADDRESS)",
            "--kube-api-qps=100",
            "--kube-api-burst=100",
            "--leader-election",
            "--leader-election-lease-duration=120s",
            "--leader-election-renew-deadline=60s",
            "--leader-election-retry-period=30s",
          ]

          env {
            name  = "ADDRESS"
            value = "/csi/csi.sock"
          }

          volume_mount {
            mount_path = "/csi"
            name       = "socket-dir"
          }
        }

        container {
          name              = "vsphere-csi-controller"
          image             = "registry.k8s.io/csi-vsphere/driver:v3.7.0"
          image_pull_policy = "Always"

          args = [
            "--fss-name=internal-feature-states.csi.vsphere.vmware.com",
            "--fss-namespace=$(CSI_NAMESPACE)",
            "--enable-profile-server=false",
          ]

          env {
            name  = "CSI_ENDPOINT"
            value = "unix:///csi/csi.sock"
          }
          env {
            name  = "X_CSI_MODE"
            value = "controller"
          }
          env {
            name  = "X_CSI_SPEC_DISABLE_LEN_CHECK"
            value = "true"
          }
          env {
            name  = "X_CSI_SERIAL_VOL_ACCESS_TIMEOUT"
            value = "3m"
          }
          env {
            name  = "VSPHERE_CSI_CONFIG"
            value = "/etc/cloud/csi-vsphere.conf"
          }
          env {
            name  = "LOGGER_LEVEL"
            value = "PRODUCTION"
          }
          env {
            name  = "INCLUSTER_CLIENT_QPS"
            value = "100"
          }
          env {
            name  = "INCLUSTER_CLIENT_BURST"
            value = "100"
          }
          env {
            name = "CSI_NAMESPACE"
            value_from {
              field_ref {
                field_path = "metadata.namespace"
              }
            }
          }

          security_context {
            run_as_non_root = true
            run_as_user     = 65532
            run_as_group    = 65532
          }

          port {
            name           = "healthz"
            container_port = 9808
            protocol       = "TCP"
          }
          port {
            name           = "prometheus"
            container_port = 2112
            protocol       = "TCP"
          }

          liveness_probe {
            http_get {
              path = "/healthz"
              port = "healthz"
            }
            initial_delay_seconds = 30
            timeout_seconds       = 10
            period_seconds        = 180
            failure_threshold     = 3
          }

          volume_mount {
            mount_path = "/etc/cloud"
            name       = "vsphere-config-volume"
            read_only  = true
          }
          volume_mount {
            mount_path = "/csi"
            name       = "socket-dir"
          }
        }

        container {
          name  = "liveness-probe"
          image = "registry.k8s.io/sig-storage/livenessprobe:v2.15.0"

          args = [
            "--v=4",
            "--csi-address=/csi/csi.sock",
          ]

          volume_mount {
            name       = "socket-dir"
            mount_path = "/csi"
          }
        }

        container {
          name              = "vsphere-syncer"
          image             = "registry.k8s.io/csi-vsphere/syncer:v3.7.0"
          image_pull_policy = "Always"

          args = [
            "--leader-election",
            "--leader-election-lease-duration=30s",
            "--leader-election-renew-deadline=20s",
            "--leader-election-retry-period=10s",
            "--fss-name=internal-feature-states.csi.vsphere.vmware.com",
            "--fss-namespace=$(CSI_NAMESPACE)",
            "--enable-profile-server=false",
          ]

          port {
            container_port = 2113
            name           = "prometheus"
            protocol       = "TCP"
          }

          env {
            name  = "FULL_SYNC_INTERVAL_MINUTES"
            value = "30"
          }
          env {
            name  = "VSPHERE_CSI_CONFIG"
            value = "/etc/cloud/csi-vsphere.conf"
          }
          env {
            name  = "LOGGER_LEVEL"
            value = "PRODUCTION"
          }
          env {
            name  = "INCLUSTER_CLIENT_QPS"
            value = "100"
          }
          env {
            name  = "INCLUSTER_CLIENT_BURST"
            value = "100"
          }
          env {
            name = "CSI_NAMESPACE"
            value_from {
              field_ref {
                field_path = "metadata.namespace"
              }
            }
          }

          security_context {
            run_as_non_root = true
            run_as_user     = 65532
            run_as_group    = 65532
          }

          volume_mount {
            mount_path = "/etc/cloud"
            name       = "vsphere-config-volume"
            read_only  = true
          }
        }

        container {
          name  = "csi-provisioner"
          image = "registry.k8s.io/sig-storage/csi-provisioner:v4.0.1"

          args = [
            "--v=4",
            "--timeout=300s",
            "--csi-address=$(ADDRESS)",
            "--kube-api-qps=100",
            "--kube-api-burst=100",
            "--leader-election",
            "--leader-election-lease-duration=120s",
            "--leader-election-renew-deadline=60s",
            "--leader-election-retry-period=30s",
            "--default-fstype=ext4",
          ]

          env {
            name  = "ADDRESS"
            value = "/csi/csi.sock"
          }

          volume_mount {
            mount_path = "/csi"
            name       = "socket-dir"
          }
        }

        container {
          name  = "csi-snapshotter"
          image = "registry.k8s.io/sig-storage/csi-snapshotter:v8.2.0"

          args = [
            "--v=4",
            "--kube-api-qps=100",
            "--kube-api-burst=100",
            "--timeout=300s",
            "--csi-address=$(ADDRESS)",
            "--leader-election",
            "--leader-election-lease-duration=120s",
            "--leader-election-renew-deadline=60s",
            "--leader-election-retry-period=30s",
            "--extra-create-metadata",
          ]

          env {
            name  = "ADDRESS"
            value = "/csi/csi.sock"
          }

          volume_mount {
            mount_path = "/csi"
            name       = "socket-dir"
          }
        }
      }
    }
  }
}

## Node DaemonSet

resource "kubernetes_daemon_set_v1" "csi_node" {
  depends_on = [
    kubernetes_config_map.csi_feature_states,
    kubernetes_service_account.csi_node,
  ]

  metadata {
    name      = "vsphere-csi-node"
    namespace = kubernetes_namespace.vmware_system_csi.metadata[0].name
  }

  spec {
    selector {
      match_labels = {
        app = "vsphere-csi-node"
      }
    }

    template {
      metadata {
        labels = {
          app  = "vsphere-csi-node"
          role = "vsphere-csi"
        }
      }

      spec {
        priority_class_name  = "system-node-critical"
        service_account_name = kubernetes_service_account.csi_node.metadata[0].name
        host_network         = true
        dns_policy           = "ClusterFirstWithHostNet"

        node_selector = {
          "kubernetes.io/os" = "linux"
        }

        toleration {
          effect   = "NoExecute"
          operator = "Exists"
        }

        toleration {
          effect   = "NoSchedule"
          operator = "Exists"
        }

        volume {
          name = "registration-dir"
          host_path {
            path = "/var/lib/kubelet/plugins_registry"
            type = "Directory"
          }
        }

        volume {
          name = "plugin-dir"
          host_path {
            path = "/var/lib/kubelet/plugins/csi.vsphere.vmware.com"
            type = "DirectoryOrCreate"
          }
        }

        volume {
          name = "pods-mount-dir"
          host_path {
            path = "/var/lib/kubelet"
            type = "Directory"
          }
        }

        volume {
          name = "device-dir"
          host_path {
            path = "/dev"
          }
        }

        volume {
          name = "blocks-dir"
          host_path {
            path = "/sys/block"
            type = "Directory"
          }
        }

        volume {
          name = "sys-devices-dir"
          host_path {
            path = "/sys/devices"
            type = "Directory"
          }
        }

        container {
          name  = "node-driver-registrar"
          image = "registry.k8s.io/sig-storage/csi-node-driver-registrar:v2.13.0"

          args = [
            "--v=5",
            "--csi-address=$(ADDRESS)",
            "--kubelet-registration-path=$(DRIVER_REG_SOCK_PATH)",
          ]

          env {
            name  = "ADDRESS"
            value = "/csi/csi.sock"
          }
          env {
            name  = "DRIVER_REG_SOCK_PATH"
            value = "/var/lib/kubelet/plugins/csi.vsphere.vmware.com/csi.sock"
          }

          volume_mount {
            name       = "plugin-dir"
            mount_path = "/csi"
          }
          volume_mount {
            name       = "registration-dir"
            mount_path = "/registration"
          }

          liveness_probe {
            exec {
              command = [
                "/csi-node-driver-registrar",
                "--kubelet-registration-path=/var/lib/kubelet/plugins/csi.vsphere.vmware.com/csi.sock",
                "--mode=kubelet-registration-probe",
              ]
            }
            initial_delay_seconds = 3
          }
        }

        container {
          name              = "vsphere-csi-node"
          image             = "registry.k8s.io/csi-vsphere/driver:v3.7.0"
          image_pull_policy = "Always"

          args = [
            "--fss-name=internal-feature-states.csi.vsphere.vmware.com",
            "--fss-namespace=$(CSI_NAMESPACE)",
          ]

          env {
            name = "NODE_NAME"
            value_from {
              field_ref {
                field_path = "spec.nodeName"
              }
            }
          }
          env {
            name  = "CSI_ENDPOINT"
            value = "unix:///csi/csi.sock"
          }
          env {
            name  = "MAX_VOLUMES_PER_NODE"
            value = "59"
          }
          env {
            name  = "X_CSI_MODE"
            value = "node"
          }
          env {
            name  = "X_CSI_SPEC_REQ_VALIDATION"
            value = "false"
          }
          env {
            name  = "X_CSI_SPEC_DISABLE_LEN_CHECK"
            value = "true"
          }
          env {
            name  = "LOGGER_LEVEL"
            value = "PRODUCTION"
          }
          env {
            name = "CSI_NAMESPACE"
            value_from {
              field_ref {
                field_path = "metadata.namespace"
              }
            }
          }
          env {
            name  = "NODEGETINFO_WATCH_TIMEOUT_MINUTES"
            value = "1"
          }

          security_context {
            privileged                 = true
            allow_privilege_escalation = true
            capabilities {
              add = ["SYS_ADMIN"]
            }
          }

          port {
            name           = "healthz"
            container_port = 9808
            protocol       = "TCP"
          }

          liveness_probe {
            http_get {
              path = "/healthz"
              port = "healthz"
            }
            initial_delay_seconds = 10
            timeout_seconds       = 5
            period_seconds        = 5
            failure_threshold     = 3
          }

          volume_mount {
            name       = "plugin-dir"
            mount_path = "/csi"
          }
          volume_mount {
            name              = "pods-mount-dir"
            mount_path        = "/var/lib/kubelet"
            mount_propagation = "Bidirectional"
          }
          volume_mount {
            name       = "device-dir"
            mount_path = "/dev"
          }
          volume_mount {
            name       = "blocks-dir"
            mount_path = "/sys/block"
          }
          volume_mount {
            name       = "sys-devices-dir"
            mount_path = "/sys/devices"
          }
        }

        container {
          name  = "liveness-probe"
          image = "registry.k8s.io/sig-storage/livenessprobe:v2.15.0"

          args = [
            "--v=4",
            "--csi-address=/csi/csi.sock",
          ]

          volume_mount {
            name       = "plugin-dir"
            mount_path = "/csi"
          }
        }
      }
    }
  }
}

## Webhook Deployment

resource "kubernetes_deployment" "csi_webhook" {
  depends_on = [
    kubernetes_secret.vsphere_webhook_certs,
    kubernetes_config_map.csi_feature_states,
    kubernetes_service_account.csi_webhook,
  ]

  metadata {
    name      = "vsphere-csi-webhook"
    namespace = kubernetes_namespace.vmware_system_csi.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "vsphere-csi-webhook"
      }
    }

    template {
      metadata {
        labels = {
          app  = "vsphere-csi-webhook"
          role = "vsphere-csi-webhook"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.csi_webhook.metadata[0].name
        dns_policy           = "Default"

        affinity {
          node_affinity {
            required_during_scheduling_ignored_during_execution {
              node_selector_term {
                match_expressions {
                  key      = "node-role.kubernetes.io/control-plane"
                  operator = "Exists"
                }
              }
              node_selector_term {
                match_expressions {
                  key      = "node-role.kubernetes.io/controlplane"
                  operator = "Exists"
                }
              }
              node_selector_term {
                match_expressions {
                  key      = "node-role.kubernetes.io/master"
                  operator = "Exists"
                }
              }
            }
          }
        }

        toleration {
          key      = "node-role.kubernetes.io/master"
          operator = "Exists"
          effect   = "NoSchedule"
        }

        toleration {
          key      = "node-role.kubernetes.io/control-plane"
          operator = "Exists"
          effect   = "NoSchedule"
        }

        volume {
          name = "socket-dir"
          empty_dir {}
        }

        volume {
          name = "webhook-certs"
          secret {
            secret_name = kubernetes_secret.vsphere_webhook_certs.metadata[0].name
          }
        }

        container {
          name              = "vsphere-webhook"
          image             = "registry.k8s.io/csi-vsphere/syncer:v3.7.0"
          image_pull_policy = "Always"

          args = [
            "--operation-mode=WEBHOOK_SERVER",
            "--fss-name=internal-feature-states.csi.vsphere.vmware.com",
            "--fss-namespace=$(CSI_NAMESPACE)",
          ]

          env {
            name  = "WEBHOOK_CONFIG_PATH"
            value = "/run/secrets/tls/webhook.config"
          }
          env {
            name  = "LOGGER_LEVEL"
            value = "PRODUCTION"
          }
          env {
            name = "CSI_NAMESPACE"
            value_from {
              field_ref {
                field_path = "metadata.namespace"
              }
            }
          }

          security_context {
            run_as_non_root = true
            run_as_user     = 65532
            run_as_group    = 65532
          }

          volume_mount {
            mount_path = "/run/secrets/tls"
            name       = "webhook-certs"
            read_only  = true
          }
        }
      }
    }
  }
}

## ValidatingWebhookConfiguration

resource "kubernetes_manifest" "csi_validating_webhook" {
  depends_on = [
    kubernetes_service.csi_webhook,
    kubernetes_deployment.csi_webhook,
  ]

  manifest = {
    apiVersion = "admissionregistration.k8s.io/v1"
    kind       = "ValidatingWebhookConfiguration"
    metadata = {
      name = "validation.csi.vsphere.vmware.com"
    }
    webhooks = [{
      name = "validation.csi.vsphere.vmware.com"
      clientConfig = {
        service = {
          name      = "vsphere-webhook-svc"
          namespace = "vmware-system-csi"
          path      = "/validate"
        }
        caBundle = base64encode(tls_self_signed_cert.webhook_ca.cert_pem)
      }
      rules = [
        {
          apiGroups   = ["storage.k8s.io"]
          apiVersions = ["v1", "v1beta1"]
          operations  = ["CREATE", "UPDATE"]
          resources   = ["storageclasses"]
        },
        {
          apiGroups   = [""]
          apiVersions = ["v1", "v1beta1"]
          operations  = ["CREATE"]
          resources   = ["persistentvolumes"]
        },
        {
          apiGroups   = [""]
          apiVersions = ["v1", "v1beta1"]
          operations  = ["UPDATE", "DELETE"]
          resources   = ["persistentvolumeclaims"]
          scope       = "Namespaced"
        },
      ]
      sideEffects             = "None"
      admissionReviewVersions = ["v1"]
      failurePolicy           = "Fail"
    }]
  }
}

## StorageClass

resource "kubernetes_storage_class" "vsphere_csi" {
  depends_on = [
    kubernetes_deployment.csi_controller,
    kubernetes_daemon_set_v1.csi_node,
  ]

  metadata {
    name = "vsphere-csi-sc"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner    = "csi.vsphere.vmware.com"
  reclaim_policy         = "Delete"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true

  parameters = {
    datastoreURL = var.vsphere.datastore_url
  }
}

## Output

output "storage_class_name" {
  value = kubernetes_storage_class.vsphere_csi.metadata[0].name
}
