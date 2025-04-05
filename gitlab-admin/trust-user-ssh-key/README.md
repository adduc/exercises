# Trusting an SSH key for a GitLab user through the Rails Console

This exercise shows how GitLab's Rails console can be used to trust an SSH key for a particular GitLab user. This is useful during automated setups or in situations where impersonating a user is not enabled in GitLab.

## Assumptions

- GitLab is deployed through Kubernetes using the GitLab Helm chart.
- You have access to the cluster where GitLab is deployed and can run `kubectl` commands.

## Usage

A Makefile is provided to simplify the process of accessing the Rails console. You can use the following command to attempt to trust an SSH key for a user:

```bash
make kubernetes/run
```

This command will print a ruby snippet and pipe it into the Rails console (accessed through a kubectl command execution). If the SSH key is already trusted, it will notify you accordingly.

## Customization

At the top of the Makefile, there are multiple variables you can customize to fit your environment:

```makefile
GITLAB_USERNAME ?= root

KUBE_CONFIG ?= ~/.kube/config
KUBE_NAMESPACE ?= gitlab
KUBE_CTL ?= kubectl
KUBE_ARGS ?= --kubeconfig=$(KUBE_CONFIG) -n $(KUBE_NAMESPACE)
```

These variables can be passed in when invoking the `make` command, or you can modify them directly in the Makefile to match your environment.

You can specify a different GitLab username or Kubernetes namespace by overriding the variables when calling `make`:

```bash
make kubernetes/run GITLAB_USERNAME=myuser KUBE_NAMESPACE=gitlab-namespace
```
