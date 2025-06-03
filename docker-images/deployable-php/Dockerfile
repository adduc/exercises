FROM alpine:3.22

RUN apk add --no-cache \
  openssh-server \
  php84-cli \
  rsync

ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
