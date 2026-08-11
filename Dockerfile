FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG XUI_VERSION=v3.5.0

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl wget nginx tar gzip openssl tzdata procps iproute2 \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /usr/local/x-ui /data/x-ui /var/log/x-ui \
    && ARCH=amd64 \
    && curl -4fL --retry 5 --retry-delay 2 \
       -o /tmp/x-ui.tar.gz \
       "https://github.com/MHSanaei/3x-ui/releases/download/${XUI_VERSION}/x-ui-linux-${ARCH}.tar.gz" \
    && tar -xzf /tmp/x-ui.tar.gz -C /tmp \
    && cp -a /tmp/x-ui/. /usr/local/x-ui/ \
    && chmod +x /usr/local/x-ui/x-ui /usr/local/x-ui/bin/xray-linux-amd64 \
    && rm -rf /tmp/x-ui /tmp/x-ui.tar.gz

COPY nginx.conf.template /etc/nginx/nginx.conf
COPY entrypoint.sh /entrypoint.sh
COPY healthcheck.sh /healthcheck.sh
COPY railway-init.sh /railway-init.sh

RUN chmod +x /entrypoint.sh /healthcheck.sh /railway-init.sh

ENV XUI_PORT=2053 \
    XUI_INIT_WEB_BASE_PATH=/panel/ \
    XUI_DB_FOLDER=/data/x-ui \
    XUI_LOG_FOLDER=/data/x-ui/log \
    XRAY_VMESS_AEAD_FORCED=false

EXPOSE 8080

CMD ["/entrypoint.sh"]
