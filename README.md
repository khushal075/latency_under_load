# Latency Under Load

A production-style benchmarking and observability platform for studying how Python backend architecture choices affect reliability, latency, throughput, and failure behavior under real traffic pressure.

This project compares synchronous and asynchronous Python backends across multiple workload patterns, worker configurations, and database connection strategies — with full observability using Prometheus and Grafana.

The goal is not simply to compare frameworks, but to understand:

- how systems behave under saturation
- where bottlenecks emerge
- how tail latency degrades
- how connection management affects reliability
- how concurrency models change failure behavior

---

## Quick Start

### Start infrastructure

```bash
make setup
```

or

```bash
./scripts/start_infra.sh
```

### Run a server

```bash
# Sync
./scripts/sync/gunicorn_4.sh

# Async
./scripts/async/uvicorn_4.sh
```

### Run all benchmarks

```bash
./scripts/run_benchmarks.sh
```

### Access dashboards

- Grafana → http://localhost:3000
- Prometheus → http://localhost:9090

---

## The Result That Started Everything

Two servers.

Same API.
Same PostgreSQL database.
Same hardware.
400 simultaneous users.

One dropped nearly half its requests.
The other dropped none.

### io_bound Scenario · 100 VUs · 2 Minutes

| Configuration | Failure Rate | p95 Latency | RPS |
|---|---|---|---|
| Gunicorn 1 worker · direct | 47.4% | 309ms | 283 |
| Gunicorn 4 workers · direct | 3.8% | 88ms | 344 |
| Gunicorn threads · direct | 29.3% | 134ms | 9 |
| Gunicorn 4 workers · pgbouncer | 0.7% | 74ms | 352 |
| **Uvicorn 1 worker · direct** | **0%** | **173ms** | **292** |
| **Uvicorn 4 workers · direct** | **0%** | **113ms** | **342** |
| **Uvicorn 4 workers · pgbouncer** | **0%** | **71ms** | **355** |

### stress_test Scenario · 400 VUs · 10 Minutes

| Configuration | Failure Rate | p95 Latency |
|---|---|---|
| Gunicorn 4 workers · direct | 40.8% | 148ms |
| Gunicorn 4 workers · pgbouncer | 0.65% | 73ms |
| Uvicorn 1 worker · direct | 0.01% | 66ms |
| **Uvicorn 4 workers · direct** | **0%** | **59ms** |
| **Uvicorn 4 workers · pgbouncer** | **0%** | **60ms** |

---

## Why It Happens

Synchronous workers block while waiting for database I/O.

Under low traffic this is mostly invisible.
Under high concurrency, those waits accumulate.

As requests pile up:
- workers stop accepting new work
- queues grow
- connections saturate
- failures cascade

An asynchronous server can continue serving other requests while awaiting I/O, allowing a single worker to multiplex hundreds of concurrent connections efficiently.

The most surprising result was that:

> A single async worker with direct PostgreSQL connections outperformed four synchronous workers under sustained load — without PgBouncer.

This suggests the dominant bottleneck was not CPU, but connection wait time and request queue buildup.

---

## Key Findings

### 1. Async reliability behaves differently under load

Every async configuration maintained near-zero failures across all major scenarios.

This was not a small optimization improvement — it represented a fundamentally different failure pattern under saturation.

---

### 2. PgBouncer dramatically improves sync stability

PgBouncer reduced failure rates for synchronous workloads from:

```text
40.8% → 0.65%
```

Connection reuse and transaction pooling significantly reduced connection pressure on PostgreSQL.

---

### 3. Threaded Gunicorn underperformed worker-based concurrency

The threaded configuration consistently performed worse than multi-worker Gunicorn.

Likely contributing factors included:
- scheduling overhead
- database connection contention
- queue buildup under sustained concurrency

---

### 4. Async has tradeoffs under held-connection workloads

The `connection_hold` scenario simulated long-lived connections such as:
- streaming
- long polling
- slow clients

Under this workload:
- async p95 latency increased significantly
- sync workers showed more predictable latency

This demonstrates that async architectures are not universally superior — workload characteristics matter.

---

### 5. Tail latency reveals failures earlier than averages

Average latency often looked acceptable even while:
- p95 degraded sharply
- queues grew rapidly
- requests failed

This reinforces why:
- percentile monitoring
- saturation metrics
- error rates

are more meaningful than averages alone.

---

## Benchmark Scenarios

| Scenario | VUs | Duration | Purpose |
|---|---|---|---|
| `io_bound` | 0 → 100 | 2 min | Simulated database wait workloads |
| `connection_hold` | 0 → 100 | 2 min | Long-held DB connections |
| `burst` | 0 → 200 | 30 sec | Sudden traffic spike |
| `stress_test` | 0 → 400 | 10 min | Sustained high concurrency |

---

## Configurations Tested

### Sync Stack

| Configuration | Workers | Threads |
|---|---|---|
| `gunicorn_1` | 1 | 1 |
| `gunicorn_4` | 4 | 1 |
| `gunicorn_threads` | 1 | 4 |

Stack:
- FastAPI
- Gunicorn
- psycopg2

---

### Async Stack

| Configuration | Workers |
|---|---|
| `uvicorn_1` | 1 |
| `uvicorn_4` | 4 |

Stack:
- FastAPI
- Uvicorn
- asyncpg

Each configuration was tested:
- with direct PostgreSQL connections
- with PgBouncer transaction pooling

---

## Architecture

```text
                    +-------------------+
                    |       k6          |
                    |  Load Generator   |
                    +---------+---------+
                              |
               +--------------+--------------+
               |                             |
    +----------+----------+      +-----------+----------+
    |   Sync App          |      |   Async App          |
    | FastAPI + Gunicorn  |      | FastAPI + Uvicorn    |
    +----------+----------+      +-----------+----------+
               |                             |
               +-------------+---------------+
                             |
                  +----------+----------+
                  |      PgBouncer      |
                  |   Transaction Pool  |
                  +----------+----------+
                             |
                  +----------+----------+
                  |     PostgreSQL      |
                  +----------+----------+
                             |
         +-------------------+-------------------+
         |               Observability           |
         |   Prometheus → Grafana Dashboards     |
         +---------------------------------------+
```

---

## Observability

The platform includes dashboards for:

- p50 / p95 / p99 latency
- requests per second
- PostgreSQL connections
- PgBouncer pool utilization
- container CPU and memory usage
- error rates
- throughput trends

Dashboard files:

```text
observability/grafana/dashboards/
```

---

## Benchmark Methodology

- Python 3.11
- PostgreSQL transaction workloads
- PgBouncer transaction pooling mode
- Metrics collected through Prometheus
- Benchmarks executed with k6
- No caching layer enabled
- Local Docker-based environment
- Identical infrastructure across all tests

The goal was comparative consistency rather than absolute production throughput numbers.

---

## Project Structure

```text
apps/
├── async_app/          # FastAPI + asyncpg
├── sync_app/           # FastAPI + psycopg2
└── shared/

load-test/
├── k6/
│   ├── scenarios/
│   └── runners/
└── results/

experiments/
├── scenario-a-sync-db/
├── scenario-b-sync-pgbouncer/
├── scenario-c-async-db/
└── scenario-d-async-pgbouncer/

infra/
├── docker/
└── k8s/

observability/
├── grafana/
└── prometheus/

scripts/
├── sync/
├── async/
└── run_benchmarks.sh
```

---

## Running Locally

### Prerequisites

- Docker
- Docker Compose
- Python 3.11+
- k6
- Make

---

### Start Infrastructure

```bash
make setup
```

---

### Run Benchmarks

```bash
./scripts/run_benchmarks.sh
```

Results are stored in:

```text
load-test/results/
```

---

## Kubernetes Deployment

```bash
kubectl apply -f infra/k8s/
```

Deploys:
- application services
- PostgreSQL
- PgBouncer
- Prometheus
- Grafana
- exporters
- HPA configuration

---

## Engineering Lessons

### Average latency can hide catastrophic failure

During some stress tests:
- average latency appeared acceptable
- while large portions of requests failed entirely

Tail latency and error rate exposed the real bottleneck behavior.

---

### Horizontal scaling does not eliminate database contention

Adding application workers improved throughput only until:
- connection saturation
- queue buildup
- database pressure

became dominant constraints.

---

### Connection management is a first-class scalability concern

PgBouncer significantly stabilized synchronous workloads by:
- reducing connection churn
- improving reuse
- limiting concurrent DB pressure

---

### Workload shape matters more than framework choice

Async architectures excelled under:
- high concurrency
- I/O-heavy workloads

But long-held connection scenarios showed meaningful tradeoffs.

---

## Limitations

These benchmarks intentionally focus on:
- I/O-bound workloads
- database-heavy request patterns

They do not represent:
- CPU-bound workloads
- multi-node distributed databases
- geographically distributed systems

Results may vary across:
- kernel/network configurations
- hardware environments
- production deployment topologies

---

## Planned Improvements

- OpenTelemetry tracing
- Jaeger distributed tracing
- chaos engineering scenarios
- network fault injection
- automated benchmark reporting
- benchmark history persistence
- CPU-bound workload comparison
- Redis caching experiments
- Kafka-based async workload simulation
- CI/CD benchmark automation

---

## Why This Project Exists

Most backend projects demonstrate:
- APIs
- CRUD operations
- framework usage

This project focuses on:
- saturation behavior
- concurrency models
- failure patterns
- observability
- tail latency
- production bottlenecks

The emphasis is on understanding how systems behave under pressure.

---

## Author

**Khushal Singh**

Senior Backend Engineer focused on:
- distributed systems
- concurrency
- scalability
- observability
- performance engineering
- backend architecture