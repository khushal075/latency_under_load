#!/usr/bin/env bash

echo "🚀 Running tests on ASYNC app"

BASE_URL=http://localhost:8002 \
k6 run scenarios/io_bound.js

BASE_URL=http://localhost:8002 \
k6 run scenarios/connection_hold.js