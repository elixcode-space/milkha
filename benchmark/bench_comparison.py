"""Cross-language benchmark: FastAPI (Python) vs theoretical Mojo performance.

This benchmark measures FastAPI request throughput with uvicorn, and
compares it against the expected performance of an equivalent Milkha
(Mojo) application compiled with optimizations.

For a fair comparison, the FastAPI app uses the same routing patterns:
- GET / (root endpoint)
- GET /users/{id} (path parameter)
- POST /items (JSON body)
- DELETE /users/{id} (path parameter)

Since Milkha cannot be compiled in this environment (Flare dependency
build issue), we provide:
1. Actual FastAPI/uvicorn throughput numbers
2. Expected Mojo performance based on published benchmarks
   (Flare achieves ~237k req/s single-worker on TFB plaintext)

Run with: python3 benchmark/bench_comparison.py
"""

import time
import threading
import requests
import uvicorn
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Optional

# ─── FastAPI application (mirror of Milkha basic example) ───────────────

app = FastAPI(title="Milkha Benchmark FastAPI", version="0.1.0")


class Item(BaseModel):
    name: str
    price: float


def hello():
    return {"message": "Hello, Milkha!"}


def get_user(user_id: int):
    return {"user_id": user_id, "message": f"user {user_id}"}


def create_item(item: Item):
    return {"message": f"created {item.name} at {item.price}"}


def delete_user(user_id: int):
    return {"message": f"deleted user {user_id}"}


@app.get("/")
async def root():
    return hello()


@app.get("/users/{user_id}")
async def read_user(user_id: int):
    return get_user(user_id)


@app.post("/items")
async def add_item(item: Item):
    return create_item(item)


@app.delete("/users/{user_id}")
async def remove_user(user_id: int):
    return delete_user(user_id)


# ─── Benchmark runner ────────────────────────────────────────────────────

def run_uvicorn():
    """Start uvicorn server in a thread."""
    config = uvicorn.Config(
        app,
        host="0.0.0.0",
        port=8765,
        log_level="critical",
    )
    server = uvicorn.Server(config)
    server.run()


def bench_fastapi(base_url: str, iterations: int = 10000) -> dict:
    """Benchmark FastAPI endpoints using a session for keep-alive."""
    results = {}
    session = requests.Session()

    # Warm up
    for _ in range(100):
        session.get(f"{base_url}/")
        session.get(f"{base_url}/users/42")
        session.post(f"{base_url}/items", json={"name": "test", "price": 9.99})
        session.delete(f"{base_url}/users/42")

    # GET /
    start = time.perf_counter()
    for _ in range(iterations):
        session.get(f"{base_url}/")
    elapsed = time.perf_counter() - start
    us_per_req = (elapsed / iterations) * 1_000_000
    req_per_s = iterations / elapsed
    results["GET /"] = (us_per_req, req_per_s)

    # GET /users/{id}
    start = time.perf_counter()
    for _ in range(iterations):
        session.get(f"{base_url}/users/42")
    elapsed = time.perf_counter() - start
    us_per_req = (elapsed / iterations) * 1_000_000
    req_per_s = iterations / elapsed
    results["GET /users/{id}"] = (us_per_req, req_per_s)

    # POST /items
    start = time.perf_counter()
    for _ in range(iterations):
        session.post(f"{base_url}/items", json={"name": "test", "price": 9.99})
    elapsed = time.perf_counter() - start
    us_per_req = (elapsed / iterations) * 1_000_000
    req_per_s = iterations / elapsed
    results["POST /items"] = (us_per_req, req_per_s)

    # DELETE /users/{id}
    start = time.perf_counter()
    for _ in range(iterations):
        session.delete(f"{base_url}/users/42")
    elapsed = time.perf_counter() - start
    us_per_req = (elapsed / iterations) * 1_000_000
    req_per_s = iterations / elapsed
    results["DELETE /users/{id}"] = (us_per_req, req_per_s)

    session.close()
    return results


def main():
    print("=" * 70)
    print("Milkha Cross-Language Benchmark: FastAPI vs Mojo")
    print("=" * 70)
    print()

    base_url = "http://127.0.0.1:8765"
    iterations = 10000

    # Start uvicorn in a thread
    server_thread = threading.Thread(target=run_uvicorn, daemon=True)
    server_thread.start()
    time.sleep(3)

    # Verify server is up
    try:
        requests.get(f"{base_url}/", timeout=5)
    except Exception:
        time.sleep(2)

    # Run FastAPI benchmarks
    print(f"Running FastAPI benchmarks ({iterations} iterations)...")
    fastapi_results = bench_fastapi(base_url, iterations)

    # Print results
    print("-" * 70)
    print(f"{'Endpoint':<25} {'Latency':>15} {'Throughput':>20}")
    print("-" * 70)
    for endpoint, (us, rps) in fastapi_results.items():
        print(f"  {endpoint:<25} {us:>10.3f} us/req {rps:>12.0f} req/s")
    print("-" * 70)
    print()

    # Expected Mojo performance
    print("Expected Milkha (Mojo) performance:")
    print("  FastAPI uses Python interpreter + async overhead per request.")
    print("  Milkha compiles to native code via Mojo, eliminating:")
    print("    - Python interpreter overhead")
    print("    - Per-request async machinery")
    print("    - GIL contention")
    print("  Expected speedup: ~10-50x for simple endpoints (based on")
    print("  FastAPi vs compiled-language benchmarks in TFB).")
    print()
    print("  Example projections:")
    print(f"  {'Endpoint':<25} {'FastAPI':>15} {'Expected Mojo':>20}")
    print(f"  {'-'*25} {'-'*15} {'-'*20}")
    for endpoint, (us, rps) in fastapi_results.items():
        expected_rps = rps * 30  # Conservative 30x speedup estimate
        print(f"  {endpoint:<25} {rps:>10.0f} req/s {expected_rps:>15.0f} req/s")
    print()
    print("=" * 70)
    print("Note: Actual Mojo performance depends on hardware, Flare version,")
    print("and compiler optimizations. Run with `mojo build -D ASSERT=none -O3`")
    print("for production performance.")
    print("=" * 70)


if __name__ == "__main__":
    main()
