# Lessons Learned

## 1. Async changes failure behavior

The biggest observation was not latency improvement,
but reliability improvement under saturation.

---

## 2. Tail latency matters more than averages

Average metrics masked severe degradation.

p95/p99 exposed:
- queue buildup
- worker saturation
- timeout amplification

---

## 3. Connection management is critical

Improper connection handling caused:
- saturation
- queue growth
- cascading failures