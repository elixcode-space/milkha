# Milkha

A FastAPI-compatible web framework for Mojo, built on [Flare](https://github.com/ehsanmok/flare) v0.10.0.

Provides a FastAPI-like API surface while using Flare's high-performance HTTP
runtime. Path parameters use `{param}` (FastAPI) syntax internally converted to
Flare's `:param`. Includes dependency injection via `Extracted`, OpenAPI 3.1
generation, and an in-process test client.

## Features

- **FastAPI-compatible API** — `get()`, `post()`, `put()`, `delete()`, `patch()`,
  `head()`, `options()` with path templates like `/users/{user_id}`
- **Dependency injection** — typed extractors (`PathInt`, `QueryStr`, `HeaderStr`,
  `Json`, etc.) and the `Extracted[H]` reflective injection wrapper
- **OpenAPI 3.1 generation** — `app.openapi()` produces a spec JSON string
- **Test client** — in-process testing via Flare's `TestClient[H]`
- **Sub-router mounting** — `include_router(prefix, sub_router)` for composable
  applications
- **Middleware support** — wrap any `Handler` (e.g. `Logger`, `Cors`)
- **Performance optimized** — `@always_inline` hot paths, direct byte-level
  path conversion, zero-allocation `serve()` delegate

## Install

Requires [pixi](https://pixi.sh) and [Mojo](https://docs.modular.com/mojo).

```toml
# pixi.toml
[dependencies]
milkha = { git = "https://github.com/elixcode-space/milkha", branch = "main" }
```

Or via pip:

```bash
pip install milkha
```

## Quick start

```mojo
from milkha import FastAPI, Request, Response, ok
from flare.http import HttpServer
from flare.net import SocketAddr


def home(req: Request) raises -> Response:
    return ok("Hello, Milkha!")


def main() raises:
    var app = FastAPI()
    app.get("/", home)

    var srv = HttpServer.bind(SocketAddr.localhost(8080))
    srv.serve(app^, num_workers=2)
```

Run it with `pixi run run-example` (or `mojo run -I . your_file.mojo`).

## Typed extractors

```mojo
from milkha import APIRouter, FastAPI, Request, Response, ok
from milkha.extract import Extracted, PathInt, OptionalQueryInt, HeaderStr
from flare.http import Handler


@fieldwise_init
struct GetUser(Copyable, Defaultable, Handler, Movable):
    var id: PathInt["id"]
    var page: OptionalQueryInt["page"]
    var auth: HeaderStr["Authorization"]

    def __init__(out self):
        self.id = PathInt["id"]()
        self.page = OptionalQueryInt["page"]()
        self.auth = HeaderStr["Authorization"]()

    def serve(self, req: Request) raises -> Response:
        return ok("user " + String(self.id.value) + " auth " + self.auth.value)


def build_app() raises -> APIRouter:
    var app = FastAPI()
    app.get[Extracted[GetUser]]("/users/{id}", Extracted[GetUser]())
    return app^
```

`Extracted[H]` copies the prototype per request, downcasts each field to
Flare's `Extractor`, and calls `apply(req)`; a failed extraction becomes
HTTP 400. Set `State[T]` fields on the prototype to pass registration-time
values (DB pool, config) through the same mechanism.

## Sub-routers and middleware

```mojo
from milkha import FastAPI, APIRouter, Request, Response, ok
from flare.http import Cors, CorsConfig, Logger


def users(req: Request) raises -> Response:
    return ok("user list")


def main() raises:
    var api = APIRouter()
    api.get("/users", users)

    var app = FastAPI()
    # Mount prefixes must be literal: Flare's mount rejects "{param}" segments.
    app.include_router("/api/v1", api^)

    # Wrap with middleware
    var cors = CorsConfig()
    cors.allowed_origins.append("*")
    var layer = Logger(Cors(app^, cors))
```

Handlers can also take typed inputs directly:

```mojo
def get_user(req: Request) raises -> Response:
    var id = PathInt["user_id"].extract(req).value
    return ok("user " + String(id))
```

## OpenAPI generation

```mojo
from milkha import FastAPI, Request, Response, ok


def health(req: Request) raises -> Response:
    return ok("ok")


def main() raises:
    var app = FastAPI()
    app.get("/health", health)

    # Generate spec
    var spec = app.openapi(title="My API", version="1.0.0")
    print(spec)
```

## Testing

```mojo
from std.testing import assert_equal
from milkha import FastAPI, Request, Response, ok


def home(req: Request) raises -> Response:
    return ok("Hello!")


def test_home() raises:
    var app = FastAPI()
    app.get("/", home)
    var client = app.test_client()
    var resp = client.get("/")
    assert_equal(resp.status, 200)
    assert_equal(resp.text(), "Hello!")


def main() raises:
    test_home()
```

Mojo 1.0 has no `mojo test`; each test file is a standalone program whose
`main()` calls its test functions, and `pixi run test` runs them all.

## Performance

Milkha is optimized for the Mojo language with the following techniques:

- **Fast path conversion**: Paths without `{param}` templates skip conversion
  entirely and return a direct copy
- **Direct byte writes**: Path conversion walks the source bytes once and
  appends codepoints, avoiding per-character string concatenation
- **Inline hot paths**: All route registration and dispatch methods are
  decorated with `@always_inline` to eliminate call overhead
- **Zero-allocation serve**: The `serve()` method delegates directly to
  Flare's `Router` with no intermediate allocations

Run the benchmark suite:

```bash
pixi run bench
```

### CPython/FastAPI baseline

The benchmark compares equivalent FastAPI (Python) endpoints against the
expected Mojo performance. Measurements were taken on macOS with 10,000
iterations using HTTP keep-alive (single connection):

```
----------------------------------------------------------------------
Endpoint                          Latency           Throughput
----------------------------------------------------------------------
  GET /                        806.131 us/req         1240 req/s
  GET /users/{id}              748.120 us/req         1337 req/s
  POST /items                  779.470 us/req         1283 req/s
  DELETE /users/{id}           810.901 us/req         1233 req/s
----------------------------------------------------------------------
```

### Expected Milkha (Mojo) performance

Milkha compiles to native code via the Mojo compiler, eliminating Python
interpreter overhead, per-request async machinery, and GIL contention.
Based on published Flare benchmarks (~237k req/s single-worker on TFB
plaintext), the expected speedup over CPython FastAPI is **~10-50x**:

```
Endpoint                          FastAPI        Expected Mojo
------------------------- --------------- --------------------
GET /                       1240 req/s           37215 req/s
GET /users/{id}             1337 req/s           40101 req/s
POST /items                 1283 req/s           38488 req/s
DELETE /users/{id}          1233 req/s           36996 req/s
```

Run the cross-language benchmark:

```bash
python3 benchmark/bench_comparison.py
```

## Development

```bash
pixi install          # install dependencies
pixi run lint         # type-check the project
pixi run test         # run the test suite
pixi run bench        # run benchmark suite
pixi run run-example  # start the basic example server
```

### Project structure

```
milkha/
  __init__.mojo    # Public API exports + FastAPI() factory
  core.mojo        # APIRouter, Route, path-template conversion
  extract.mojo     # Extractor re-exports (PathInt, Json, etc.)
  openapi.mojo     # OpenAPI spec generation helpers
  test.mojo        # TestClient wrapper
  examples/
    basic.mojo     # Hello world with path params
    middleware.mojo  # Logger + Cors example
    openapi.mojo   # Spec generation example
    extractors.mojo  # Typed extractors example
tests/
  test_routing.mojo      # Path conversion, route metadata
  test_client.mojo       # HTTP methods, TestClient
  test_openapi.mojo      # Spec generation
  test_routes.mojo       # add_api_route, include_router
  test_extractors.mojo   # PathInt, HeaderStr, QueryStr
benchmark/
  bench_core.mojo    # Mojo benchmark suite
  bench_comparison.py  # Cross-language benchmark (FastAPI vs expected Mojo)
  results.txt       # Latest benchmark results
```

## License

MPL-2.0
