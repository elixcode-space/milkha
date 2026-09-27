"""Middleware example: Logger + Cors stacking on a Milkha router.

Run with: `pixi run example middleware`
"""

from milkha import APIRouter, Request, Response, ok
from milkha.extract import PathInt
from flare.http import Cors, CorsConfig, Logger
from flare.net import SocketAddr


def home(req: Request) raises -> Response:
    return ok("home")


def items(req: Request) raises -> Response:
    var id = PathInt["id"].extract(req).value
    return ok("item " + String(id))


def main() raises:
    from flare.http import HttpServer

    var router = APIRouter()
    router.get("/", home)
    router.get("/items/{id}", items)

    # Wrap with CORS and Logger middleware
    var cors_config = CorsConfig()
    cors_config.allowed_origins.append("*")
    cors_config.allowed_methods.append("GET")
    cors_config.allowed_methods.append("POST")
    cors_config.allow_credentials = False

    var cors_layer = Cors(router^, cors_config)
    var logger_layer = Logger(cors_layer^)

    var srv = HttpServer.bind(SocketAddr.localhost(8080))
    srv.serve(logger_layer^, num_workers=2)
