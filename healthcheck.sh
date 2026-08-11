#!/usr/bin/env bash
set -e
curl -fsS "http://127.0.0.1:${PORT:-8080}/healthz" >/dev/null
