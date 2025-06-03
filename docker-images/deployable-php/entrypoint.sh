#!/bin/sh

# shellcheck disable=SC3040
set -o nounset -o errexit -o pipefail

[ -z "${DEBUG:-}" ] || set -o xtrace

generate_host_keys() {
  [ ! -f /etc/ssh/ssh_host_rsa_key ] || return 0
  mkdir -p /etc/ssh
  ssh-keygen -A
}

create_user() {
  UID=${UID:-1000}
  GID=${GID:-1000}

  if ! id -u user >/dev/null 2>&1; then
    adduser -u "$UID" -g "$GID" -D user
    echo "user:*" | chpasswd -e
  fi
}

start_ssh() {
  exec /usr/sbin/sshd -D -e \
    -o LogLevel=VERBOSE
}

main() {
  generate_host_keys
  create_user
  start_ssh
}

main "$@"
