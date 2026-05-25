vsphere = {
  user                 = "user@example.com"
  password             = "password"
  vsphere_server       = "url.to.vsphere.server"
  allow_unverified_ssl = true
}

vm = {
  name                          = "vsphere-csi-demo"
  folder_path                   = "examples"
  cluster_name                  = "cluster"
  datastore_name                = "datastore"
  network_name                  = "network"
  template_name                 = "Alpine-3.23-Golden-NoCloud"
  user_data_username            = "example"
  user_data_ssh_public_key_path = "~/.ssh/id_ed25519.pub"
}
