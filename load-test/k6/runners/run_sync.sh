#!/usr/bin/env bash

echo "🔥 Running tests on SYNC app"

BASE_URL=http://localhost:8001 \
k6 run scenarios/io_bound.js

BASE_URL=http://localhost:8001 \
k6 run scenarios/connection_hold.js