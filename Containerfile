FROM debian:trixie-20261005

RUN apt-get update \
    && apt-get upgrade -y \
    && apt install -y --no-install-recommends curl ca-certificates unzip gnupg socat ncat tini \
    && curl -fsSL https://awscli.amazonaws.com/v2/install.sh | bash -s -- --system \
    && curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_arm64/session-manager-plugin.deb" -o /tmp/session-manager-plugin.deb \
    && dpkg -i /tmp/session-manager-plugin.deb \
    && rm -f /tmp/session-manager-plugin.deb \
    && apt-get remove -y curl unzip \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["tini", "-g", "--", "/entrypoint.sh"]
