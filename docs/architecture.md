# Architecture

## System Components

- k6 load generators
- sync backend
- async backend
- PostgreSQL
- PgBouncer
- Prometheus
- Grafana

---

## Why FastAPI?

Chosen because:
- supports ASGI
- easy async experimentation
- lightweight stack
- minimal framework overhead

---

## Why PgBouncer?

To study:
- connection reuse
- transaction pooling
- DB saturation behavior

---

## Why k6?

Chosen because:
- lightweight scripting
- concurrent VU simulation
- good metrics support