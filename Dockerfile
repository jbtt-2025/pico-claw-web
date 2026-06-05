# syntax=docker/dockerfile:1.7

ARG PICOCLAW_IMAGE=docker.io/sipeed/picoclaw:launcher
FROM ${PICOCLAW_IMAGE}

USER root

ENV PICOCLAW_HOME=/var/data/picoclaw \
    NPM_CONFIG_UPDATE_NOTIFIER=false \
    NPM_CONFIG_FUND=false \
    NPM_CONFIG_AUDIT=false \
    SAL_USE_VCLPLUGIN=gen

RUN apk add --no-cache \
      bash \
      curl \
      git \
      openssh-client \
      jq \
      ripgrep \
      fd \
      tree \
      tmux \
      make \
      build-base \
      cmake \
      github-cli \
      python3 \
      python3-dev \
      py3-pip \
      nodejs \
      npm \
      pandoc \
      libreoffice \
      poppler-utils \
      qpdf \
      ghostscript \
      fontconfig \
      font-noto \
      font-noto-cjk \
      ttf-dejavu \
    && fc-cache -f \
    && mkdir -p /var/data/picoclaw \
    && mkdir -p /root/.config/pip \
    && cat > /root/.config/pip/pip.conf <<'EOF'
[global]
break-system-packages = true
EOF

RUN npm install -g pnpm \
    && pip3 install --no-cache-dir \
      uv \
      markdown \
      beautifulsoup4 \
      lxml \
      python-docx \
      openpyxl \
      python-pptx \
      pypdf \
      pymupdf \
      redis \
      'psycopg[binary]' \
      pymysql \
      mysql-connector-python \
      sqlalchemy

RUN chmod -R 777 /var/data \
    && cat > /usr/local/bin/md2pdf <<'EOF'
#!/bin/sh
set -eu

if [ "$#" -lt 1 ]; then
  echo "Usage: md2pdf input.md [output.pdf]" >&2
  exit 1
fi

INPUT="$1"
OUTPUT="${2:-${INPUT%.*}.pdf}"
TMP_HTML="$(mktemp /tmp/md2pdf.XXXXXX.html)"

pandoc "$INPUT" \
  --standalone \
  --metadata pagetitle="${INPUT}" \
  -o "$TMP_HTML"

soffice \
  --headless \
  --convert-to pdf \
  --outdir "$(dirname "$OUTPUT")" \
  "$TMP_HTML" >/tmp/md2pdf.log 2>&1 || {
    cat /tmp/md2pdf.log >&2
    rm -f "$TMP_HTML"
    exit 1
  }

GENERATED="$(dirname "$OUTPUT")/$(basename "${TMP_HTML%.*}.pdf")"
mv "$GENERATED" "$OUTPUT"
rm -f "$TMP_HTML"

echo "$OUTPUT"
EOF

RUN chmod +x /usr/local/bin/md2pdf \
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
    bash --version | head -n 1; \
    python3 --version; \
    python3-config --includes; \
    pip3 --version; \
    uv --version; \
    python3 - <<'PY'
import redis
import psycopg
import pymysql
import mysql.connector
import sqlalchemy
print("python db clients ok")
PY
    node --version; \
    npm --version; \
    pnpm --version; \
    git --version; \
    ssh -V; \
    gh --version | head -n 1; \
    jq --version; \
    rg --version | head -n 1; \
    fd --version; \
    tree --version; \
    tmux -V; \
    make --version | head -n 1; \
    cmake --version | head -n 1; \
    pandoc --version | head -n 1; \
    soffice --version; \
    pdfinfo -v 2>&1 | head -n 1; \
    qpdf --version | head -n 1; \
    gs --version; \
    md2pdf --help || true; \
    pip3 config list

EXPOSE 18800 18790

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD sh -c 'curl -fsS "http://127.0.0.1:${PORT:-18800}/" >/dev/null'

ENTRYPOINT ["/usr/local/bin/picoclaw-web-entrypoint.sh"]
