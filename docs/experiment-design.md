# Experiment Design

## Objective

Compare:
- sync vs async concurrency behavior
- direct DB vs pooled connections

under sustained traffic.

---

## Variables

### Independent Variables

- worker model
- connection pooling
- concurrency level

### Dependent Variables

- p95 latency
- throughput
- failures
- DB connections

---

## Controlled Variables

- same hardware
- same PostgreSQL config
- same request patterns
- same dataset