import psycopg2
from psycopg2 import pool
import os
import time

# Load the connection string from the environment
DATABASE_URL = os.getenv('DATABASE_URL')

# Initialize the pool:
# minconn=5 (always keep 5 ready)
# maxconn=20 (never open more than 20, even if under heavy load)
try:
    connection_pool = psycopg2.pool.ThreadedConnectionPool(5, 20, DATABASE_URL)
    print("✅ Database connection pool initialized successfully.")
except Exception as e:
    print(f"❌ Error creating connection pool: {e}")
    connection_pool = None

def get_conn_from_pool():
    if connection_pool is None:
        raise ConnectionError("❌ Database connection pool is not available. Check your DATABASE_URL.")
    return connection_pool.getconn()

def run_query(delay: float):
    """Simulates a standard database-heavy IO operation."""
    conn = get_conn_from_pool()
    try:
        cur = conn.cursor()
        # The CPU waits here while Postgres sleeps
        cur.execute(f"SELECT pg_sleep({delay});")
        cur.close()
        return "ok"
    except Exception as e:
        print(f"Query Error: {e}")
        return "error"
    finally:
        # CRITICAL: Returns the connection to the pool so others can use it
        connection_pool.putconn(conn)

def hold_connection(delay: float):
    """Simulates a worst-case scenario: DB wait PLUS Python logic wait."""
    conn = get_conn_from_pool()
    try:
        cur = conn.cursor()
        cur.execute(f"SELECT pg_sleep({delay});")
        # 🔥 This blocks the worker thread without using the DB
        time.sleep(delay)
        cur.close()
        return "held"
    except Exception as e:
        print(f"Hold Error: {e}")
        return "error"
    finally:
        connection_pool.putconn(conn)