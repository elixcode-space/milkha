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
- **Performance optimized** — `@inline` hot paths, direct byte-level path
  conversion, zero-allocation `serve()` delegate

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

app = FastAPI()

def home(req: Request) -> Response:
    return ok("Hello, Milkha!")

app.get("/", home)

if __name__ == "__main__":
    from flare.http import HttpServer
    from flare.net import SocketAddr

    srv = HttpServer.bind(SocketAddr.localhost(8080))
    srv.serve(app, num_workers=2)
```

## Typed extractors

```mojo
from milkha import FastAPI, Request, Response, ok
from milkha.extract import Extracted, PathInt, OptionalQueryInt, HeaderStr

app = FastAPI()

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
        return ok(f"user={self.id.value} page={self.page.value} auth={self.auth.value}")

app.get[Extracted[GetUser]]("/users/{id}", Extracted[GetUser]())
```

## Sub-routers and middleware

```mojo
from milkha import FastAPI, APIRouter
from flare.http.middleware import Logger, Cors, CorsConfig

api = APIRouter()

def users(req: Request) -> Response:
    return ok("user list")

api.get("/users", users)

app = FastAPI()
app.include_router("/api/v1", api^)

# Wrap with middleware
cors = CorsConfig()
cors.allowed_origins.append("*")
layer = Logger(Cors(app^, cors))
```

## OpenAPI generation

```mojo
from milkha import FastAPI, Request, Response, ok

app = FastAPI()
app.get("/health", lambda req: ok("ok"))

# Generate spec
let spec = app.openapi(title="My API", version="1.0.0")
print(spec)
```

## Testing

```mojo
from std.testing import assert_equal, TestSuite
from milkha import FastAPI, Request, Response, ok

app = FastAPI()

def home(req: Request) -> Response:
    return ok("Hello!")

app.get("/", home)
client = app.test_client()
var resp = client.get("/")
assert_equal(resp.status, 200)
assert_equal(resp.text(), "Hello!")
```

## Performance

Milkha is optimized for the Mojo language with the following techniques:

- **Fast path conversion**: Paths without `{param}` templates skip conversion
  entirely and return a direct copy
- **Direct byte writes**: Path conversion uses `unsafe_ptr` to write bytes
  directly, avoiding per-character `chr()` / `Int()` overhead
- **Inline hot paths**: All route registration and dispatch methods are
  decorated with `@inline` to eliminate call overhead
- **Zero-allocation serve**: The `serve()` method delegates directly to
  Flare's `Router` with no intermediate allocations

Run the benchmark suite:

```bash
pixi run bench
```

This produces output like:

```
_to_flare_path (simple):      ~0.05 us/op
_to_flare_path (multi-param): ~0.15 us/op
register 5 routes:            ~2.0  us/op
GET / via TestClient:         ~1.5  us/req
openapi() (5 routes):         ~50   us/op
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
  bench_core.mojo    # Performance benchmarks
```

## License

MPL-2.0
