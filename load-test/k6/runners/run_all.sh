#!/usr/bin/env bash

set -e

RESULT_DIR="../results/raw"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

mkdir -p "$RESULT_DIR"

echo "📁 Saving results to: $RESULT_DIR"
echo "🕒 Run ID: $TIMESTAMP"

echo "=============================="
echo "SYNC APP TEST"
echo "=============================="

BASE_URL=http://localhost:8001 k6 run scenarios/io_bound.js \
  --out json="$RESULT_DIR/sync_io_bound_$TIMESTAMP.json"

BASE_URL=http://localhost:8001 k6 run scenarios/connection_hold.js \
  --out json="$RESULT_DIR/sync_connection_hold_$TIMESTAMP.json"

echo "=============================="
echo "ASYNC APP TEST"
echo "=============================="

BASE_URL=http://localhost:8002 k6 run scenarios/io_bound.js \
  --out json="$RESULT_DIR/async_io_bound_$TIMESTAMP.json"

BASE_URL=http://localhost:8002 k6 run scenarios/connection_hold.js \
  --out json="$RESULT_DIR/async_connection_hold_$TIMESTAMP.json"

echo "=============================="
echo "✅ ALL TESTS COMPLETE"
echo "📂 Results saved in: $RESULT_DIR"
echo "=============================="