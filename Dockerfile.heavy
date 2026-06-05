# syntax=docker/dockerfile:1.7

ARG PICOCLAW_IMAGE=docker.io/sipeed/picoclaw:launcher
FROM ${PICOCLAW_IMAGE}

USER root

ENV PICOCLAW_HOME=/var/data/picoclaw \
    NPM_CONFIG_UPDATE_NOTIFIER=false \
    NPM_CONFIG_FUND=false \
    NPM_CONFIG_AUDIT=false

RUN apk add --no-cache \
      bash \
      curl \
      git \
      python3 \
      py3-pip \
      nodejs \
      npm \
    && mkdir -p /var/data/picoclaw \
    && mkdir -p /root/.config/pip \
    && cat > /root/.config/pip/pip.conf <<'EOF'
[global]
break-system-packages = true
EOF

RUN chmod -R 777 /var/data \
    && cat > /usr/local/bin/picoclaw-web-entrypoint.sh <<'EOF'
#!/bin/sh
set -eu

export PICOCLAW_HOME="${PICOCLAW_HOME:-/var/data/picoclaw}"

mkdir -p "$PICOCLAW_HOME"

WEB_PORT="${PORT:-18800}"

if [ -n "${PICOCLAW_CONFIG:-}" ]; then
  exec picoclaw-launcher \
    -console \
    -public \
    -no-browser \
    -port "$WEB_PORT" \
    "$PICOCLAW_CONFIG"
else
  exec picoclaw-launcher \
    -console \
    -public \
    -no-browser \
    -port "$WEB_PORT"
fi
EOF

RUN chmod +x /usr/local/bin/picoclaw-web-entrypoint.sh

RUN set -eux; \
    python3 --version; \
    pip3 --version; \
    node --version; \
    npm --version; \
    git --version; \
    pip3 config list

EXPOSE 18800 18790

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD sh -c 'curl -fsS "http://127.0.0.1:${PORT:-18800}/" >/dev/null'

ENTRYPOINT ["/usr/local/bin/picoclaw-web-entrypoint.sh"]
