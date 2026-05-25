#!/usr/bin/env bash

set -euo pipefail

# -----------------------------------
# Config & Environment
# -----------------------------------
SYNC_PORT=8001
ASYNC_PORT=8002
HEALTH_ENDPOINT="/health"
MAX_RETRIES=20
RUN_ID=$(date +"%Y%m%d_%H%M%S")

# The two DB modes we want to compare
MODES=("direct" "pgbouncer")

SYNC_RUNNERS=(
#  "scripts/sync/gunicorn_1.sh"
#  "scripts/sync/gunicorn_4.sh"
#  "scripts/sync/gunicorn_threads.sh"
)

ASYNC_RUNNERS=(
  "scripts/async/uvicorn_1.sh"
  "scripts/async/uvicorn_4.sh"
)

SCENARIOS=(
  "io_bound"
  "connection_hold"
  "burst"
  "stress_test"
)

# -----------------------------------
# Helpers
# -----------------------------------

kill_port() {
  local port=$1
  echo "🧹 Cleaning port $port..."
  local pids
  pids=$(lsof -ti tcp:"$port" || true)
  if [[ -n "$pids" ]]; then
    kill $pids 2>/dev/null || true
    sleep 2
    kill -9 $pids 2>/dev/null || true
  fi
}

wait_for_server() {
  local port=$1
  for ((i=1; i<=MAX_RETRIES; i++)); do
    if curl -s "http://localhost:$port$HEALTH_ENDPOINT" > /dev/null; then
      return 0
    fi
    sleep 1
  done
  return 1
}

start_server() {
  local script=$1
  local port=$2
  local mode=$3
  local log_dir="load-test/results/raw/${RUN_ID}_${mode}/logs"
  mkdir -p "$log_dir"
  local log_file="$log_dir/$(basename "$script").log"

  # 1. Parse host and port from the inherited DATABASE_URL
  # This extracts 'localhost' and '5432' or '6432'
  local db_host=$(echo "$DATABASE_URL" | sed -e 's/.*@//' -e 's/:.*//')
  local db_port=$(echo "$DATABASE_URL" | sed -e 's/.*://' -e 's/\/.*//')

  echo "🔍 Verifying DB availability ($db_host:$db_port) for $mode..."

  # 2. Wait for the DB port to be ready
  local timeout=15
  while ! nc -z "$db_host" "$db_port"; do
    echo "⏳ DB not ready... sleeping"
    sleep 1
    ((timeout--))
    if [ $timeout -le 0 ]; then
      echo "❌ DB $db_host:$db_port never became available"
      return 1
    fi
  done

  kill_port "$port"
  echo "🚀 Starting server ($mode): $script"

  # 3. Start the app
  bash "$script" > "$log_file" 2>&1 &
  SERVER_PID=$!

  if ! wait_for_server "$port"; then
    echo "❌ Server startup failed. Check $log_file"
    return 1
  fi
}

stop_server() {
  local port=$1
  echo "🛑 Stopping server (PID: $SERVER_PID)"
  kill "$SERVER_PID" 2>/dev/null || true
  sleep 2
  kill -9 "$SERVER_PID" 2>/dev/null || true
  kill_port "$port"
}

run_k6() {
  local app_type=$1
  local scenario=$2
  local port=$3
  local mode=$4

  local results_dir="load-test/results/raw/${RUN_ID}_${mode}"
  local outfile="$results_dir/${app_type}_${scenario}.json"

  echo "▶️ Running K6: $app_type | $scenario | Mode: $mode"

  BASE_URL="http://localhost:$port" \
  k6 run "load-test/k6/scenarios/${scenario}.js" \
    --out json="$outfile" \
    || echo "⚠️ k6 failed for $scenario"

  echo "⏳ Settle time for Prometheus..."
  sleep 10
}

run_suite() {
  local type=$1
  local port=$2
  local mode=$3
  shift 3
  local runners=("$@")

  echo "--- Testing $type in $mode mode ---"

  for runner in "${runners[@]}"; do
    if ! start_server "$runner" "$port" "$mode"; then
      continue
    fi

    for scenario in "${SCENARIOS[@]}"; do
      run_k6 "$type" "$scenario" "$port" "$mode"
    done

    stop_server "$port"
  done
}

cleanup() {
  echo "🧹 Global cleanup..."
  kill_port "$SYNC_PORT"
  kill_port "$ASYNC_PORT"
}

trap cleanup EXIT INT TERM

# -----------------------------------
# Execution: The Double Loop
# -----------------------------------

for MODE in "${MODES[@]}"; do
  echo "=============================================="
  echo "🌍 GLOBAL MODE: $(echo $MODE | tr '[:lower:]' '[:upper:]')"
  echo "=============================================="

  if [[ "$MODE" == "direct" ]]; then
    export DATABASE_URL="postgresql://postgres:postgres@localhost:5432/benchmark"
  else
    export DATABASE_URL="postgresql://postgres:postgres@localhost:6432/benchmark"
  fi

  #run_suite "sync" "$SYNC_PORT" "$MODE" "${SYNC_RUNNERS[@]}"
  run_suite "async" "$ASYNC_PORT" "$MODE" "${ASYNC_RUNNERS[@]}"

  echo "✅ Finished all scenarios for $MODE"
done

echo ""
echo "🏆 ALL BENCHMARKS COMPLETED!"
echo "📊 Results are in: load-test/results/raw/${RUN_ID}_direct/"
echo "📊              and load-test/results/raw/${RUN_ID}_pgbouncer/"