# Which compartment to create a new compartment in
parent_compartment_id = ""

# SSH key and CIDR configuration
ssh_authorized_key_path = "~/.ssh/id_ed25519.pub"
ssh_cidr                = "1.1.1.1/32"

# AMD-based instance configuration
instance_shape                 = "VM.Standard.E2.1.Micro" # AMD
instance_memory_in_gbs         = 1
instance_ocpus                 = 1
instance_volume_in_gbs         = 50
image_operating_system         = "Canonical Ubuntu"
image_operating_system_version = "22.04 Minimal"

# ARM-based instance configuration
# instance_shape                 = "VM.Standard.A1.Flex" # ARM
# instance_memory_in_gbs         = 24
# instance_ocpus                 = 4
# instance_volume_in_gbs         = 50
# image_operating_system         = "Canonical Ubuntu"
# image_operating_system_version = "24.04 Minimal aarch64"

## Provider Configuration
tenancy_ocid = ""
user_ocid    = ""
region       = ""
fingerprint  = "00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00"
private_key  = <<-EOF
    -----BEGIN PRIVATE KEY-----
    ... your private key here ...
    -----END PRIVATE KEY-----
EOF