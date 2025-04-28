FROM ubuntu:22.04

ARG DEP_EPHEMERAL="\
  python3-pip \
"

ARG DEP_RUNTIME="\
  python3 \
  openssh-client \
"

RUN apt-get update \
 && apt-get dist-upgrade --no-install-recommends -y \
 && apt-get autoremove --purge -y \
 && rm -rf /var/lib/apt/lists/*

ARG ANSIBLE_CORE_VERSION=2.17.11

# Install required packages
RUN apt-get update \
 && apt-get install --no-install-recommends -y ${DEP_RUNTIME} ${DEP_EPHEMERAL} \
 && pip3 install --no-cache-dir --upgrade ansible-core==${ANSIBLE_CORE_VERSION} \
 && rm -rf /var/lib/apt/lists/* \
 && touch -t 7001010000 /var/lib/apt/lists

# Set default environment variables defining the user to create
# for running ansible playbooks
ENV UID=1000 GID=1000 USER=ansible

# Create an entrypoint script to prepare the environment
ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]


CMD [ "sleep", "infinity" ]
