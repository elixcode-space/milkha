"""Benchmark for Milkha path-template conversion and core operations.

Measures the performance of:
1. _to_flare_path: FastAPI {param} -> Flare :param conversion
2. Route registration: app.get() / app.post() throughput
3. Request dispatch: TestClient end-to-end latency

Run with: `pixi run bench`
"""

from std.time import monotonic

from milkha import FastAPI, Request, Response, ok
from milkha.core import APIRouter


@always_inline
def now_ns() -> Int:
    return monotonic()


def dummy_handler(req: Request) raises -> Response:
    return ok("ok")


def bench_path_conversion(iterations: Int = 100000) raises -> Float64:
    """Benchmark _to_flare_path with a multi-param path."""
    var path = "/api/v1/orgs/{org}/repos/{repo}/issues/{issue_id}"
    var expected = "/api/v1/orgs/:org/repos/:repo/issues/:issue_id"

    var start = now_ns()
    for i in range(iterations):
        var result = APIRouter._to_flare_path(path)
        if result != expected:
            raise Error("path conversion mismatch")
    var elapsed = Float64(now_ns() - start) / 1e9

    var per_op_us = (elapsed / Float64(iterations)) * 1e6
    print(
        "_to_flare_path (multi-param): ",
        per_op_us,
        " us/op, ",
        Float64(iterations) / elapsed,
        " ops/s",
    )
    return per_op_us


def bench_path_conversion_simple(iterations: Int = 100000) raises -> Float64:
    """Benchmark _to_flare_path with a simple path (no params)."""
    var path = "/health"
    var start = now_ns()
    for i in range(iterations):
        var result = APIRouter._to_flare_path(path)
        if result != path:
            raise Error("path conversion mismatch for simple path")
    var elapsed = Float64(now_ns() - start) / 1e9

    var per_op_us = (elapsed / Float64(iterations)) * 1e6
    print(
        "_to_flare_path (simple): ",
        per_op_us,
        " us/op, ",
        Float64(iterations) / elapsed,
        " ops/s",
    )
    return per_op_us


def bench_route_registration(iterations: Int = 10000) raises -> Float64:
    """Benchmark route registration throughput."""
    var start = now_ns()
    for i in range(iterations):
        var app = APIRouter()
        app.get("/users/{id}", dummy_handler)
        app.post("/items", dummy_handler)
        app.put("/items/{id}", dummy_handler)
        app.delete("/items/{id}", dummy_handler)
        app.patch("/items/{id}", dummy_handler)
    var elapsed = Float64(now_ns() - start) / 1e9

    var per_op_us = (elapsed / Float64(iterations)) * 1e6
    print("register 5 routes: ", per_op_us, " us/op, ", Float64(iterations) / elapsed, " ops/s")
    return per_op_us


def bench_request_dispatch(iterations: Int = 50000) raises -> Float64:
    """Benchmark end-to-end request dispatch via TestClient."""
    var app = FastAPI()
    app.get("/", dummy_handler)
    app.get("/users/{id}", dummy_handler)
    app.post("/items", dummy_handler)

    var client = app.test_client()

    # Warm up
    for i in range(100):
        _ = client.get("/")

    var start = now_ns()
    for i in range(iterations):
        _ = client.get("/")
    var elapsed = Float64(now_ns() - start) / 1e9

    var per_req_us = (elapsed / Float64(iterations)) * 1e6
    print(
        "GET / via TestClient: ", per_req_us, " us/req, ", Float64(iterations) / elapsed, " req/s"
    )
    return per_req_us


def bench_request_dispatch_with_param(iterations: Int = 50000) raises -> Float64:
    """Benchmark request dispatch with path parameter extraction."""
    var app = FastAPI()
    app.get("/users/{id}", dummy_handler)

    var client = app.test_client()

    # Warm up
    for i in range(100):
        _ = client.get("/users/42")

    var start = now_ns()
    for i in range(iterations):
        _ = client.get("/users/42")
    var elapsed = Float64(now_ns() - start) / 1e9

    var per_req_us = (elapsed / Float64(iterations)) * 1e6
    print(
        "GET /users/{id} via TestClient: ",
        per_req_us,
        " us/req, ",
        Float64(iterations) / elapsed,
        " req/s",
    )
    return per_req_us


def bench_openapi_generation(iterations: Int = 1000) raises -> Float64:
    """Benchmark OpenAPI spec generation."""
    var app = FastAPI()
    app.get("/", dummy_handler)
    app.get("/users/{id}", dummy_handler)
    app.post("/items", dummy_handler)
    app.put("/items/{id}", dummy_handler)
    app.delete("/items/{id}", dummy_handler)

    var start = now_ns()
    for i in range(iterations):
        _ = app.openapi()
    var elapsed = Float64(now_ns() - start) / 1e9

    var per_op_us = (elapsed / Float64(iterations)) * 1e6
    print("openapi() (5 routes): ", per_op_us, " us/op, ", Float64(iterations) / elapsed, " ops/s")
    return per_op_us


def main() raises:
    print("=" * 60)
    print("Milkha Benchmark Suite")
    print("=" * 60)
    print()

    var simple = bench_path_conversion_simple(100000)
    var complex = bench_path_conversion(100000)
    var route_reg = bench_route_registration(10000)
    var dispatch = bench_request_dispatch(50000)
    var dispatch_param = bench_request_dispatch_with_param(50000)
    var openapi = bench_openapi_generation(1000)

    print()
    print("=" * 60)
    print("Summary:")
    print("  _to_flare_path (simple):      ", simple, " us/op")
    print("  _to_flare_path (multi-param): ", complex, " us/op")
    print("  register 5 routes:            ", route_reg, " us/op")
    print("  GET / via TestClient:         ", dispatch, " us/req")
    print("  GET /users/{id} via Test:     ", dispatch_param, " us/req")
    print("  openapi() (5 routes):         ", openapi, " us/op")
    print("=" * 60)
