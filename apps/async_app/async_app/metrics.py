from prometheus_client import Counter, Histogram

REQUEST_COUNT = Counter(
    "http_requests_total",
    "Total HTTP Requests",
    ["method", "endpoint"],
)

REQUEST_LATENCY = Histogram(
    "http_requests_duration_seconds",
    "Request latency",
    ["endpoint"],
)