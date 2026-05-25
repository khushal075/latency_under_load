from dotenv import load_dotenv
load_dotenv()
from fastapi import FastAPI, Response

from prometheus_client import generate_latest
import time

from async_app.db import init_db, run_query, hold_connection
from async_app.metrics import REQUEST_COUNT, REQUEST_LATENCY

app = FastAPI()

@app.on_event("startup")
async def startup():
    await init_db()

@app.get("/io_bound/{delay}")
async def io_bound(delay: float):
    REQUEST_COUNT.labels('GET', '/io_bound').inc()

    start = time.time()
    result = await run_query(delay)
    latency = time.time() - start

    REQUEST_LATENCY.labels('/io_bound').observe(latency)
    return {"latency": latency, "result": result}


@app.get("/connection_hold/{delay}")
async def connection_hold(delay: float):
    REQUEST_COUNT.labels('GET', '/connection_hold').inc()
    start = time.time()
    result = await hold_connection(delay)
    latency = time.time() - start
    REQUEST_LATENCY.labels('/connection_hold').observe(latency)
    return {"latency": latency, "result": result}

@app.get("/metrics")
async def metrics():
    return Response(generate_latest(), media_type="text/plain")