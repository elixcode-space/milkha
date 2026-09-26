"""Middleware example: Logger + Cors stacking on a Milkha router.

Run with: `mojo run examples/middleware.mojo`
"""

from milkha import FastAPI, Request, Response, ok, APIRouter
from milkha.extract import PathInt, Extracted
from flare.http.middleware import Logger, Cors, CorsConfig
from flare.net import SocketAddr


def home(req: Request) -> Response:
    return ok("home")


def items(req: Request) -> Response:
    let id = PathInt["id"].extract(req).value
    return ok(f"item {id.value}")


router = APIRouter()
router.get("/", home)
router.get("/items/{id}", items)

# Wrap with CORS and Logger middleware
cors_config = CorsConfig()
cors_config.allowed_origins.append("*")
cors_config.allowed_methods.append("GET")
cors_config.allowed_methods.append("POST")
cors_config.allow_credentials = False

cors_layer = Cors(router^, cors_config)
logger_layer = Logger(cors_layer)

# Run server
if __name__ == "__main__":
    from flare.http import HttpServer

    srv = HttpServer.bind(SocketAddr.localhost(8080))
    srv.serve(logger_layer, num_workers=2)