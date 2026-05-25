# Results Analysis

## Overview

This document analyzes benchmark results across:
- sync vs async backends
- direct PostgreSQL connections
- PgBouncer transaction pooling
- multiple workload patterns

---

# Major Findings

## 1. Async handled concurrency more efficiently

Under io_bound workloads:
- async configurations maintained near-zero failures
- sync workers saturated earlier
- queue buildup caused request drops

### Evidence

| Config | Failure Rate | p95 |
|---|---|---|
| gunicorn_1 | 47.4% | 309ms |
| uvicorn_1 | 0% | 173ms |

---

## 2. PgBouncer stabilized sync workloads

PgBouncer reduced:
- connection churn
- DB saturation
- timeout frequency

Stress test:

| Config | Failure Rate |
|---|---|
| gunicorn_4 direct | 40.8% |
| gunicorn_4 pgbouncer | 0.65% |

---

## 3. Tail latency degraded before averages

Average latency remained acceptable even when:
- queues grew rapidly
- failures increased
- p95/p99 worsened

This demonstrates why:
- percentile metrics
- saturation monitoring
- queue analysis

are more meaningful than averages alone.