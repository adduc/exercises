# Using NFS-backed Persistent Volumes in Kubernetes

This exercise demonstrates how the NFS CSI driver can be used to create
persistent volumes backed by an NFS share in kubernetes.

## Structure

To minimize the software required, containers are used to run a Kubernetes cluster and an NFS server. The resources are created using
OpenTofu.

## Usage

```sh
# Create containers for K3s (Kubernetes cluster) and NFS server
cd 01-compute && tofu apply

# Install csi-driver-nfs and create a storage class for an NFS share
cd ../02-cluster-resources && tofu apply

# Create a PersistentVolumeClaim and a Pod that mounts the NFS share
cd ../03-services && tofu apply

# Write to the NFS share from the Pod (can take up to two minutes for
# the initial write due to how NFS works within docker)
cd .. && kubectl --kubeconfig kubeconfig.yaml exec pod/nfs-pod -- sh -c 'echo "Hello" > /mnt/test.txt'

# We can see that the test file was created within a dynamically created
# directory representing the volume created within the NFS share
find data

# Even after destroying the Pod, the data is still available
cd 03-services && tofu destroy -target kubernetes_pod_v1.nfs-pod

# Verify that the data is still available (as it is associated with the
# PersistentVolumeClaim)
find ../data

# When creating a new Pod with the same PersistentVolumeClaim, we can
# see that the data is still available
tofu apply

# This command should print "Hello"
cd .. && kubectl --kubeconfig kubeconfig.yaml exec pod/nfs-pod -- cat /mnt/test.txt
```

## Cleanup

```sh
# Destroy k3s and NFS server containers
cd 01-compute && tofu destroy

# Delete the NFS share
cd .. && sudo rm -rf data/pvc*
```
