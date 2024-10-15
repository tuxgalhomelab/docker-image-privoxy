# syntax=docker/dockerfile:1

ARG BASE_IMAGE_NAME
ARG BASE_IMAGE_TAG
FROM ${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG} AS with-scripts

COPY scripts/start-privoxy.sh /scripts/

ARG BASE_IMAGE_NAME
ARG BASE_IMAGE_TAG
FROM ${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG}

ARG PACKAGES_TO_INSTALL
ARG USER_NAME
ARG GROUP_NAME
ARG USER_ID
ARG GROUP_ID

# hadolint ignore=SC3040
RUN --mount=type=bind,target=/scripts,from=with-scripts,source=/scripts \
    set -E -e -o pipefail \
    && export HOMELAB_VERBOSE=y \
    # Install dependencies. \
    && homelab install util-linux ${PACKAGES_TO_INSTALL:?} \
    && homelab remove util-linux \
    && mkdir -p /data/privoxy /opt/privoxy \
    && cp -rf /etc/privoxy/* /data/privoxy/ \
    && rm /data/privoxy/config \
    && touch /data/privoxy/config \
    && echo "confdir /data/privoxy" >> /data/privoxy/config \
    && echo "listen-address  :8118" >> /data/privoxy/config \
    # Copy the start-privoxy.sh script. \
    && cp /scripts/start-privoxy.sh /opt/privoxy/ \
    && ln -sf /opt/privoxy/start-privoxy.sh /opt/bin/start-privoxy \
    # Remove the existing user to allow us to set the user ID. \
    && userdel --force --remove privoxy \
    # Create the user and the group. \
    && homelab add-user \
        ${USER_NAME:?} \
        ${USER_ID:?} \
        ${GROUP_NAME:?} \
        ${GROUP_ID:?} \
        --no-create-home-dir \
    && chown -R ${USER_NAME:?}:${GROUP_NAME:?} /opt/privoxy /opt/bin/start-privoxy /data/privoxy \
    # Clean up. \
    && homelab cleanup

# Privoxy proxy.
EXPOSE 8118

HEALTHCHECK \
    --start-period=15s --interval=30s --timeout=3s \
    CMD curl \
        --silent --fail --location --show-error \
        --output /dev/null \
        --write-out '%{http_code}' \
        --head \
        --proxy 127.0.0.1:8118 \
        1.1.1.1

ENV USER=${USER_NAME}
USER ${USER_NAME}:${GROUP_NAME}
WORKDIR /

CMD ["start-privoxy"]
STOPSIGNAL SIGTERM
