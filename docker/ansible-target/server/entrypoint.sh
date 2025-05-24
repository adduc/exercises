#!/bin/bash

# Instruct bash to exit when a command returns a non-zero exit code,
# when an undefined variable is used, and to fail if piped commands
# return a non-zero exit code.
set -o nounset -o errexit -o pipefail

create_group() {
  echo "Checking if group ${USER} exists..."

  if getent group "${USER}" > /dev/null; then
    echo "Group ${USER} already exists. Skipping group creation."
    return 0
  fi

  echo "Creating group ${USER} with GID ${GID}..."

  groupadd \
    --gid "${GID}" \
    "${USER}"

  echo "Group ${USER} created successfully."
}

create_user() {
  echo "Checking if user ${USER} exists..."

  if getent passwd "${USER}" > /dev/null; then
      echo "User ${USER} already exists. Skipping user creation."
      return 0
  fi

  echo "Creating user ${USER} with UID ${UID} and GID ${GID}..."

  useradd \
    --create-home \
    --gid "${GID}" \
    --shell /bin/bash \
    --uid "${UID}" \
    "${USER}"

    echo "User ${USER} created successfully."
}

prepare_user_ssh() {
  [ -d /mnt/user-ssh ] || return 0
  echo "Preparing SSH configuration for user ${USER}..."
  mkdir -p /home/"${USER}"/.ssh

  echo "Copying SSH keys from /mnt/user-ssh to /home/${USER}/.ssh..."
  cp -r /mnt/user-ssh/* /home/"${USER}"/.ssh/

  echo "Trusting localhost SSH key..."

}

prepare_system_ssh() {
  [ -d /mnt/system-ssh ] || return 0

  echo "Trusting system SSH keys..."

  truncate -s 0 /home/"${USER}"/.ssh/known_hosts

  for file in /mnt/system-ssh/ssh_host_*.pub; do
    # use wildcard to trust fingerprint for all hostnames
    (echo -n "* "; cat "$file") >> /home/"${USER}"/.ssh/known_hosts
  done
}

set_ssh_ownership() {
  echo "Setting ownership of SSH directories and files..."

  chown -R "${USER}:${USER}" /home/"${USER}"/.ssh
  find /home/"${USER}"/.ssh -type d -exec chmod 700 {} +
  find /home/"${USER}"/.ssh -type f -exec chmod 600 {} +
}

exec_cmd() {
  echo "Executing command: $*"
  exec "$@"
}

main() {
  create_group
  create_user
  prepare_user_ssh
  prepare_system_ssh
  set_ssh_ownership
  exec_cmd "$@"
}

main "$@"
