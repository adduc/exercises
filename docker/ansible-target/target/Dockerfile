FROM ubuntu:22.04

ARG DEP_RUNTIME="\
  openssh-server \
  sudo \
  systemd \
  python3 \
  python3-apt \
"

# Install required packages
RUN apt-get update \
 && apt-get dist-upgrade -y \
 && apt-get install --no-install-recommends -y ${DEP_RUNTIME} \
 && dpkg --get-selections | grep deinstall | awk '{ print $1 }' | xargs apt-get purge -y \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && touch -t 7001010000 /var/lib/apt/lists

# Enable SSH service and remove unnecessary systemd targets/services
RUN systemctl enable /lib/systemd/system/ssh.service \
 && rm /lib/systemd/system/getty.target

# Set default environment variables defining the user to create
# for running ansible playbooks
ENV UID=1000 GID=1000 USER=ansible

# Create an entrypoint script to prepare the environment before starting
# systemd
ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]

# Systemd does not trap the default stop signal that docker
# uses, SIGTERM, so we need to set the stop signal to the signal systemd
# expects to stop services gracefully.
# @see https://www.man7.org/linux/man-pages/man1/systemd.1.html#SIGNALS
STOPSIGNAL SIGRTMIN+3
CMD [ "/lib/systemd/systemd" ]
VOLUME [ "/tmp", "/run/lock" ]
