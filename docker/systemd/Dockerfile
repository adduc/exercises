FROM ubuntu:22.04

RUN apt-get update \
 && apt-get dist-upgrade -y \
 && apt-get install --no-install-recommends -y systemd \
 && dpkg --get-selections | grep deinstall | awk '{ print $1 }' | xargs apt-get purge -y \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && touch -t 7001010000 /var/lib/apt/lists

# Systemd does not trap the default stop signal that docker
# uses, SIGTERM, so we need to set the stop signal to the signal systemd
# expects to stop services gracefully.
# @see https://www.man7.org/linux/man-pages/man1/systemd.1.html#SIGNALS
STOPSIGNAL SIGRTMIN+3
CMD [ "/lib/systemd/systemd" ]
VOLUME [ "/tmp", "/run/lock" ]
