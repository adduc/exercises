kubeconfig_path = "../../k3s_kubeconfig.yaml"

vsphere = {
  user                 = "user@example.com"
  password             = "password"
  vsphere_server       = "url.to.vsphere.server"
  allow_unverified_ssl = true
  datacenter           = "Datacenter"
  datastore_url        = "ds:///vmfs/volumes/00000000-00000000-0000-000000000000/"
  cluster_id           = "example-cluster"
}
