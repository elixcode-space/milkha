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

## Testing

```mojo
from milkha import FastAPI, Request, Response, ok

app = FastAPI()

def home(req: Request) -> Response:
    return ok("Hello!")

app.get("/", home)
client = app.test_client()
var resp = client.get("/")
```

## Development

```bash
pixi install          # install dependencies
pixi run lint         # type-check the project
pixi run test         # run the test suite
pixi run run-example  # start the basic example server
```

## License

MPL-2.0
