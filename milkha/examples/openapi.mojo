"""OpenAPI example: generate a Milkha API spec.

Run with: `pixi run example openapi`
"""

from milkha import APIRouter, FastAPI, Request, Response, ok
from milkha.extract import PathInt


def health(req: Request) raises -> Response:
    return ok("ok")


def get_user(req: Request) raises -> Response:
    var id = PathInt["id"].extract(req).value
    return ok("user " + String(id))


def build_app() raises -> APIRouter:
    var app = FastAPI()
    app.get("/", health)
    app.get("/users/{id}", get_user)
    return app^


def main() raises:
    var app = build_app()
    print(app.openapi())
