## Exercise: Using local kubeconfig if present

This exercise shows how a shell function can be used to conditionally
set the kubeconfig path for `kubectl` based on the presence of a
kubeconfig file in the current working directory.

## Usage

```bash
# load script into current shell
source main.sh

# change to directory with kubeconfig.yaml
cd ../k3s-fluxcd

# test kubectl alias
k get pods
```
