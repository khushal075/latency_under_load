#!/usr/bin/env bash

set -euo pipefail

PORT=8001

echo "🚀 Starting Gunicorn (Uvicorn Workers)"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"

exec poetry -C "$ROOT_DIR/apps/sync_app" run gunicorn sync_app.main:app \
  --chdir "$ROOT_DIR/apps/sync_app" \
  --bind 0.0.0.0:$PORT \
  --workers 2 \
  --worker-class uvicorn.workers.UvicornWorker \
  --timeout 120 \
  --graceful-timeout 30 \
  --keep-alive 5 \
  --max-requests 1000 \
  --max-requests-jitter 100 \
  --log-level info