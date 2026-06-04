FROM docker.io/sipeed/picoclaw:v0.2.9-launcher

USER root

RUN cat > /usr/local/bin/render-launcher-entrypoint.sh <<'EOF'
#!/bin/sh
set -eu

export PICOCLAW_HOME="${PICOCLAW_HOME:-/var/data/picoclaw}"
mkdir -p "$PICOCLAW_HOME"

WEB_PORT="${PORT:-10000}"

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

RUN chmod +x /usr/local/bin/render-launcher-entrypoint.sh

EXPOSE 10000

HEALTHCHECK --interval=30s --timeout=3s --start-period=15s --retries=3 \
  CMD sh -c 'curl -fsS "http://127.0.0.1:${PORT:-10000}/" >/dev/null || exit 1'

ENTRYPOINT ["/usr/local/bin/render-launcher-entrypoint.sh"]
