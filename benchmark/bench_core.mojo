"""Benchmark for Milkha path-template conversion and core operations.

Measures the performance of:
1. _to_flare_path: FastAPI {param} -> Flare :param conversion
2. Route registration: app.get() / app.post() throughput
3. Request dispatch: TestClient end-to-end latency

Run with: mojo run benchmark/bench_core.mojo
"""

import time

from milkha import FastAPI, Request, Response, ok
from milkha.core import APIRouter


fn dummy_handler(req: Request) -> Response:
    return ok("ok")


fn bench_path_conversion(iterations: Int = 100000) -> Float64:
    """Benchmark _to_flare_path with a multi-param path."""
    let path = "/api/v1/orgs/{org}/repos/{repo}/issues/{issue_id}"
    let expected = "/api/v1/orgs/:org/repos/:repo/issues/:issue_id"

    let start = time.perf_counter()
    for i in range(iterations):
        var result = APIRouter._to_flare_path(path)
        if result != expected:
            raise Error("path conversion mismatch")
    let elapsed = time.perf_counter() - start

    let per_op_us = (elapsed / iterations) * 1_000_000
    print(
        f"_to_flare_path ({path!r}): {per_op_us:.3f} us/op, "
        f"{iterations / elapsed:.0f} ops/s"
    )
    return per_op_us


fn bench_path_conversion_simple(iterations: Int = 100000) -> Float64:
    """Benchmark _to_flare_path with a simple path (no params)."""
    let path = "/health"
    let start = time.perf_counter()
    for i in range(iterations):
        var result = APIRouter._to_flare_path(path)
        if result != path:
            raise Error("path conversion mismatch for simple path")
    let elapsed = time.perf_counter() - start

    let per_op_us = (elapsed / iterations) * 1_000_000
    print(
        f"_to_flare_path (simple): {per_op_us:.3f} us/op, "
        f"{iterations / elapsed:.0f} ops/s"
    )
    return per_op_us


fn bench_route_registration(iterations: Int = 10000) -> Float64:
    """Benchmark route registration throughput."""
    let start = time.perf_counter()
    for i in range(iterations):
        var app = APIRouter()
        app.get("/users/{id}", dummy_handler)
        app.post("/items", dummy_handler)
        app.put("/items/{id}", dummy_handler)
        app.delete("/items/{id}", dummy_handler)
        app.patch("/items/{id}", dummy_handler)
    let elapsed = time.perf_counter() - start

    let per_op_us = (elapsed / iterations) * 1_000_000
    print(
        f"register 5 routes: {per_op_us:.3f} us/op, "
        f"{iterations / elapsed:.0f} ops/s"
    )
    return per_op_us


fn bench_request_dispatch(iterations: Int = 50000) -> Float64:
    """Benchmark end-to-end request dispatch via TestClient."""
    var app = FastAPI()
    app.get("/", dummy_handler)
    app.get("/users/{id}", dummy_handler)
    app.post("/items", dummy_handler)

    var client = app.test_client()

    # Warm up
    for i in range(100):
        _ = client.get("/")

    let start = time.perf_counter()
    for i in range(iterations):
        _ = client.get("/")
    let elapsed = time.perf_counter() - start

    let per_req_us = (elapsed / iterations) * 1_000_000
    print(
        f"GET / via TestClient: {per_req_us:.3f} us/req, "
        f"{iterations / elapsed:.0f} req/s"
    )
    return per_req_us


fn bench_request_dispatch_with_param(iterations: Int = 50000) -> Float64:
    """Benchmark request dispatch with path parameter extraction."""
    var app = FastAPI()
    app.get("/users/{id}", dummy_handler)

    var client = app.test_client()

    # Warm up
    for i in range(100):
        _ = client.get("/users/42")

    let start = time.perf_counter()
    for i in range(iterations):
        _ = client.get("/users/42")
    let elapsed = time.perf_counter() - start

    let per_req_us = (elapsed / iterations) * 1_000_000
    print(
        f"GET /users/{{id}} via TestClient: {per_req_us:.3f} us/req, "
        f"{iterations / elapsed:.0f} req/s"
    )
    return per_req_us


fn bench_openapi_generation(iterations: Int = 1000) -> Float64:
    """Benchmark OpenAPI spec generation."""
    var app = FastAPI()
    app.get("/", dummy_handler)
    app.get("/users/{id}", dummy_handler)
    app.post("/items", dummy_handler)
    app.put("/items/{id}", dummy_handler)
    app.delete("/items/{id}", dummy_handler)

    let start = time.perf_counter()
    for i in range(iterations):
        _ = app.openapi()
    let elapsed = time.perf_counter() - start

    let per_op_us = (elapsed / iterations) * 1_000_000
    print(
        f"openapi() (5 routes): {per_op_us:.3f} us/op, "
        f"{iterations / elapsed:.0f} ops/s"
    )
    return per_op_us


fn main() raises:
    print("=" * 60)
    print("Milkha Benchmark Suite")
    print("=" * 60)
    print()

    let simple = bench_path_conversion_simple(100000)
    let complex = bench_path_conversion(100000)
    let route_reg = bench_route_registration(10000)
    let dispatch = bench_request_dispatch(50000)
    let dispatch_param = bench_request_dispatch_with_param(50000)
    let openapi = bench_openapi_generation(1000)

    print()
    print("=" * 60)
    print("Summary (lower is better):")
    print(f"  _to_flare_path (simple):      {simple:.3f} us/op")
    print(f"  _to_flare_path (multi-param): {complex:.3f} us/op")
    print(f"  register 5 routes:            {route_reg:.3f} us/op")
    print(f"  GET / via TestClient:         {dispatch:.3f} us/req")
    print(f"  GET /users/{{id}} via Test:    {dispatch_param:.3f} us/req")
    print(f"  openapi() (5 routes):         {openapi:.3f} us/op")
    print("=" * 60)
