"""Basic Milkha example: hello world with path parameters.

Run with: `pixi run example basic`
Then visit http://localhost:8080
"""

from milkha import APIRouter, FastAPI, Request, Response, ok
from milkha.extract import PathInt, HeaderStr


def home(req: Request) raises -> Response:
    return ok("Hello, Milkha!")


def get_user(req: Request) raises -> Response:
    return ok("user " + req.param("user_id"))


def get_item(req: Request) raises -> Response:
    var item_id = PathInt["item_id"].extract(req).value
    var user_agent = HeaderStr["User-Agent"].extract(req).value
    return ok("item " + String(item_id) + " for " + user_agent)


def build_app() raises -> APIRouter:
    var app = FastAPI()
    app.get("/", home)
    app.get("/users/{user_id}", get_user)
    app.get("/items/{item_id}", get_item)
    return app^


def main() raises:
    from flare.http import HttpServer
    from flare.net import SocketAddr

    var app = build_app()
    var srv = HttpServer.bind(SocketAddr.localhost(8080))
    srv.serve(app^, num_workers=2)
