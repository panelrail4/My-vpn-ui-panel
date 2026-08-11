#!/usr/bin/env bash
set -euo pipefail

echo "Railway 3X-UI initialization helper"
echo "Public domain: ${RAILWAY_PUBLIC_DOMAIN:-not-set}"
echo "Public HTTPS endpoint: https://${RAILWAY_PUBLIC_DOMAIN:-<railway-domain>}:443"
echo "Panel path: ${XUI_INIT_WEB_BASE_PATH:-/panel/}"
echo
echo "Reserved internal Xray ports:"
echo "  WS            8081"
echo "  XHTTP         8082"
echo "  gRPC          8083"
echo "  HTTP Upgrade  8084"
