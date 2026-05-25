from dotenv import load_dotenv
load_dotenv()

import time
from fastapi import FastAPI, Response
from prometheus_client import generate_latest
from sync_app.metrics import REQUEST_COUNT, REQUEST_LATENCY
from sync_app.db import run_query, hold_connection

app = FastAPI()

@app.get("/io_bound/{delay}")
def io_bound(delay: float):
    REQUEST_COUNT.labels('GET', '/io_bound').inc()

    start = time.time()
    result = run_query(delay)
    latency = time.time() - start
    REQUEST_LATENCY.labels('/io_bound').observe(latency)
    return {"latency": latency, "result": result}


@app.get("/connection_hold/{delay}")
def connection_hold(delay: float):
    REQUEST_COUNT.labels('GET', '/connection_hold').inc()
    start = time.time()
    result = hold_connection(delay)
    latency = time.time() - start
    REQUEST_LATENCY.labels('/connection_hold').observe(latency)
    return {"latency": latency, "result": result}


@app.get("/metrics")
def metrics():
    return Response(generate_latest(), media_type="text/plain")