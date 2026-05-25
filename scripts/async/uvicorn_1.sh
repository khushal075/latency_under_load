#!/usr/bin/env bash

set -euo pipefail

PORT=8002

echo "🚀 Starting Uvicorn (1 worker)"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
APP_DIR="$ROOT_DIR/apps/async_app"

exec poetry -C "$APP_DIR" run uvicorn async_app.main:app \
  --app-dir "$APP_DIR" \
  --host 0.0.0.0 \
  --port $PORT \
  --workers 1 \
  --loop uvloop \
  --http httptools \
  --timeout-keep-alive 5 \
  --log-level info