#!/bin/bash

# kubectl alias
# - if kubeconfig.yaml exists in the current working directory, use it
# - otherwise, use the default kubeconfig path
k() {
  ARGS=""

  # if kubeconfig.yaml exists in the current working directory, use it
  [ -f "kubeconfig.yaml" ] && ARGS="--kubeconfig kubeconfig.yaml"

  # shellcheck disable=SC2086 # ARGS is purposefully unquoted
  kubectl $ARGS "$@"
}