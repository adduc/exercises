# Using Samba-backed Persistent Volumes in Kubernetes

This exercise demonstrates how the SMB CSI driver can be used to create
persistent volumes backed by an Samba share in kubernetes.

## Structure

To minimize the software required, containers are used to run a Kubernetes cluster and an Samba server. The resources are created using
OpenTofu.

## Usage

```sh

# Create a directory to store the Samba share
mkdir -p data

# Ensure the SMB CSI driver can create directories within the Samba share
chmod 777 data

# Create containers for K3s (Kubernetes cluster) and Samba server
cd 01-compute && tofu apply

# Install csi-driver-smb and create a storage class for an Samba share
cd ../02-cluster-resources && tofu apply

# Create a PersistentVolumeClaim and a Pod that mounts the Samba share
cd ../03-services && tofu apply

# Write to the Samba share from the Pod (can take up to two minutes for
# the initial write due to how Samba works within docker)
cd .. && kubectl --kubeconfig kubeconfig.yaml exec pod/smb-pod -- sh -c 'echo "Hello" > /mnt/test.txt'

# We can see that the test file was created within a dynamically created
# directory representing the volume created within the Samba share
find data

# Even after destroying the Pod, the data is still available
cd 03-services && tofu destroy -target kubernetes_pod_v1.smb-pod

# Verify that the data is still available (as it is associated with the
# PersistentVolumeClaim)
find ../data

# When creating a new Pod with the same PersistentVolumeClaim, we can
# see that the data is still available
tofu apply

# This command should print "Hello"
cd .. && kubectl --kubeconfig kubeconfig.yaml exec pod/smb-pod -- cat /mnt/test.txt
```

## Cleanup

```sh
# Destroy k3s and Samba server containers
cd 01-compute && tofu destroy

# Delete the Samba share
cd .. && sudo rm -rf data/pvc*
```
