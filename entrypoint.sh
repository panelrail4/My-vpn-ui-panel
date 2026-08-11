#!/usr/bin/env bash
set -Eeuo pipefail

mkdir -p /data/x-ui /data/x-ui/log /data/x-ui/bin /var/log/nginx /run/nginx
touch /data/x-ui/log/3x-ui.log

export XUI_PORT="${XUI_PORT:-2053}"
export XUI_INIT_WEB_BASE_PATH="${XUI_INIT_WEB_BASE_PATH:-/panel/}"
export XUI_DB_FOLDER="${XUI_DB_FOLDER:-/data/x-ui}"
export XUI_LOG_FOLDER="${XUI_LOG_FOLDER:-/data/x-ui/log}"

if [[ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]]; then
  echo "[railway-3xui] Public domain: ${RAILWAY_PUBLIC_DOMAIN}"
fi

# The upstream binary expects its working tree/resources in /usr/local/x-ui.
cd /usr/local/x-ui

# Persist generated/runtime resources outside the image.
if [[ ! -e /usr/local/x-ui/db ]]; then
  ln -s /data/x-ui /usr/local/x-ui/db
fi

# Generate nginx configuration from Railway runtime variables.
envsubst '${PORT} ${XUI_PORT}' < /etc/nginx/nginx.conf > /tmp/nginx.conf
command -v envsubst >/dev/null 2>&1 || { echo "[railway-3xui] ERROR: envsubst is missing; install gettext-base"; exit 1; }
nginx -t -c /tmp/nginx.conf

# Start official 3X-UI. It supervises the bundled Xray core.
echo "[railway-3xui] starting official 3X-UI on 127.0.0.1:${XUI_PORT}"
XUI_PORT="${XUI_PORT}" XUI_INIT_WEB_BASE_PATH="${XUI_INIT_WEB_BASE_PATH}" XUI_DB_FOLDER="${XUI_DB_FOLDER}" XUI_LOG_FOLDER="${XUI_LOG_FOLDER}" XUI_BIN_FOLDER="${XUI_BIN_FOLDER}" /usr/local/x-ui/x-ui run >>/data/x-ui/log/3x-ui.log 2>&1 &
XUI_PID=$!

# Give the panel a short startup window.
for i in $(seq 1 60); do
  if curl -fsS "http://127.0.0.1:${XUI_PORT}${XUI_INIT_WEB_BASE_PATH}" >/dev/null 2>&1; then
    break
  fi
  if ! kill -0 "${XUI_PID}" 2>/dev/null; then
    echo "[railway-3xui] 3X-UI exited during startup"
    tail -100 /data/x-ui/log/3x-ui.log || true
    exit 1
  fi
  sleep 1
done

echo "[railway-3xui] starting nginx on Railway PORT=${PORT}"
nginx -c /tmp/nginx.conf -g 'daemon off;' &
NGINX_PID=$!

cleanup() {
  kill "${NGINX_PID}" 2>/dev/null || true
  kill "${XUI_PID}" 2>/dev/null || true
}
trap cleanup SIGTERM SIGINT EXIT

wait -n "${XUI_PID}" "${NGINX_PID}"
status=$?
echo "[railway-3xui] process exited: ${status}"
tail -80 /data/x-ui/log/3x-ui.log || true
exit "${status}"
