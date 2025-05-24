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
}

grant_sudo_access() {
    echo "Checking if sudo access is already granted to ${USER}..."

    if sudo -l -U "${USER}" | grep -q '(ALL : ALL) ALL'; then
        echo "Sudo access already granted to ${USER}. Skipping sudo configuration."
        return 0
    fi

    echo "Granting sudo access to ${USER}..."

    echo "${USER} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/"${USER}"
    chmod 0440 /etc/sudoers.d/"${USER}"
    chown root:root /etc/sudoers.d/"${USER}"
}

prepare_user_ssh() {
  [ -d /mnt/user-ssh ] || return 0

  echo "Preparing SSH configuration for user ${USER}..."
  mkdir -p /home/"${USER}"/.ssh

  echo "Copying SSH keys from /mnt/user-ssh to /home/${USER}/.ssh..."
  cp -r /mnt/user-ssh/* /home/"${USER}"/.ssh/

  echo "Allowing SSH keys in /home/${USER}/.ssh to be used for authentication..."
  cat /home/"${USER}"/.ssh/*.pub > /home/"${USER}"/.ssh/authorized_keys
}

prepare_system_ssh() {
  [ -d /mnt/system-ssh ] || return 0

  echo "Copying system SSH keys from /mnt/system-ssh to /etc/ssh..."
  mkdir -p /etc/ssh
  cp -r /mnt/system-ssh/ssh_host_* /etc/ssh/
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
  grant_sudo_access
  prepare_user_ssh
  prepare_system_ssh
  set_ssh_ownership

  exec_cmd "$@"
}

main "$@"
