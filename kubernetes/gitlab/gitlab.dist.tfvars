# Password to use when initially provisioning the root gitlab user.
initial_root_password = ""

# Value to set as the personal access token for the root user when
# initially provisioning GitLab. This can be used to authenticate API
# calls.
root_personal_access_token = ""

ssh_host_ecdsa_key = <<-EOT
  -----BEGIN OPENSSH PRIVATE KEY-----
  ...
  -----END OPENSSH PRIVATE KEY-----
EOT

ssh_host_ecdsa_key_pub = <<-EOT
  ecdsa-sha2-nistp256 ...
EOT

ssh_host_ed25519_key = <<-EOT
  -----BEGIN OPENSSH PRIVATE KEY-----
  ...
  -----END OPENSSH PRIVATE KEY-----
EOT

ssh_host_ed25519_key_pub = <<-EOT
  ssh-ed25519 ...
EOT

ssh_host_rsa_key = <<-EOT
  -----BEGIN OPENSSH PRIVATE KEY-----
  ...
  -----END OPENSSH PRIVATE KEY-----
EOT

ssh_host_rsa_key_pub = <<-EOT
  ssh-rsa ...
EOT
