import asyncpg
import os

print("DATABASE_URL =", os.getenv("DATABASE_URL"))

DATABASE_URL = os.environ.get("DATABASE_URL")

pool = None

async def init_db():
    global pool
    pool = await asyncpg.create_pool(
        DATABASE_URL,
        min_size=5,
        max_size=20,
        statement_cache_size=0,
    )

async def run_query(delay: float):
    async with pool.acquire() as conn:
        await conn.execute(f"SELECT pg_sleep({delay});")
    return "ok"

async def hold_connection(delay: float):
   async with pool.acquire() as conn:
       await conn.execute(f"SELECT pg_sleep({delay});")

       # simulate holding connection without blocking event loop
       await conn.execute(f"SELECT pg_sleep({delay});")

   return "held"
