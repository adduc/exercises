FROM adduc/ansible-alpine:3.23-amd64

# py3-pyvomi: used for vSphere interaction by Ansible
# qemu-image: used to convert Alpine Cloud image to VMDK format
# cdrkit: used to create ISO image for cloud-init user-data and meta-data
RUN apk add --no-cache py3-pyvmomi qemu-img cdrkit
