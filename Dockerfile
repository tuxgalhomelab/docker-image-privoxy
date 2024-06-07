ARG BASE_IMAGE_NAME
ARG BASE_IMAGE_TAG
FROM ${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG}

SHELL ["/bin/bash", "-c"]

ARG PACKAGES_TO_INSTALL

RUN \
    set -e -o pipefail \
    # Install dependencies. \
    && homelab install util-linux ${PACKAGES_TO_INSTALL:?} \
    && homelab remove util-linux \
    && mkdir -p /privoxy \
    && cp -rf /etc/privoxy/* /privoxy/ \
    && rm /privoxy/config \
    && touch /privoxy/config \
    && echo "confdir /privoxy" >> /privoxy/config \
    && echo "listen-address  :8118" >> /privoxy/config \
    # Clean up. \
    && homelab cleanup

# Privoxy proxy.
EXPOSE 8118

WORKDIR /
CMD ["privoxy", "--no-daemon", "/privoxy/config"]
