#!/usr/bin/env bash
set -Eeuo pipefail

export PORT="${PORT:-8080}"
export XUI_PORT="${XUI_PORT:-2053}"
export XUI_INIT_WEB_BASE_PATH="${XUI_INIT_WEB_BASE_PATH:-/panel/}"
export XUI_DB_FOLDER="${XUI_DB_FOLDER:-/data/x-ui}"
export XUI_LOG_FOLDER="${XUI_LOG_FOLDER:-/data/x-ui/log}"

mkdir -p \
  /data/x-ui \
  /data/x-ui/log \
  /data/x-ui/bin \
  /var/log/nginx \
  /run/nginx

touch /data/x-ui/log/3x-ui.log

if [[ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]]; then
  echo "[railway-3xui] Public domain: ${RAILWAY_PUBLIC_DOMAIN}"
fi

# Build nginx configuration from Railway runtime variables.
if ! command -v envsubst >/dev/null 2>&1; then
  echo "[railway-3xui] ERROR: envsubst is missing (gettext-base must be installed)"
  exit 1
fi

envsubst '${PORT} ${XUI_PORT}' < /etc/nginx/nginx.conf > /tmp/nginx.conf
nginx -t -c /tmp/nginx.conf

cd /usr/local/x-ui

echo "[railway-3xui] starting official 3X-UI on 127.0.0.1:${XUI_PORT}"

# Start official 3X-UI without fragile environment-variable expansion.
/usr/local/x-ui/x-ui run >>/data/x-ui/log/3x-ui.log 2>&1 &
XUI_PID=$!

echo "[railway-3xui] 3X-UI PID=${XUI_PID}"

# Wait briefly for the panel to become reachable.
for i in $(seq 1 60); do
  if curl -fsS "http://127.0.0.1:${XUI_PORT}${XUI_INIT_WEB_BASE_PATH}" >/dev/null 2>&1; then
    echo "[railway-3xui] 3X-UI is ready"
    break
  fi

  if ! kill -0 "${XUI_PID}" 2>/dev/null; then
    echo "[railway-3xui] 3X-UI exited during startup"
    tail -100 /data/x-ui/log/3x-ui.log || true
    exit 1
  fi

  sleep 1
done

if ! kill -0 "${XUI_PID}" 2>/dev/null; then
  echo "[railway-3xui] 3X-UI is not running"
  tail -100 /data/x-ui/log/3x-ui.log || true
  exit 1
fi

echo "[railway-3xui] starting nginx on Railway PORT=${PORT}"
nginx -c /tmp/nginx.conf -g 'daemon off;' &
NGINX_PID=$!

cleanup() {
  kill "${NGINX_PID}" 2>/dev/null || true
  kill "${XUI_PID}" 2>/dev/null || true
}
trap cleanup SIGTERM SIGINT EXIT

# Keep the container alive while both services are running.
while kill -0 "${XUI_PID}" 2>/dev/null && kill -0 "${NGINX_PID}" 2>/dev/null; do
  sleep 2
done

echo "[railway-3xui] a required process exited"
tail -100 /data/x-ui/log/3x-ui.log || true
exit 1
