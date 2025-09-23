# Running a Wireguard VPN server with Docker

This exercise demonstrates using the [linuxserver.io Wireguard container](https://hub.docker.com/r/linuxserver/wireguard) to quickly stand up a Wireguard VPN server. The configuration is done through environment variables, and the server can be started and stopped using a Makefile.


## Thoughts

I appreciate that through environment configuration a wireguard instance can be stood up with multiple peers. While I wouldn't want to use this for production environments where the server needs to stay up and running as new peers are added, it is a great way to quickly spin up a wireguard server for personal use.

