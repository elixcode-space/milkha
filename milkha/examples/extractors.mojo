"""Typed extractors example: using Extracted and Flare extractors.

Demonstrates Extracted[H] for auto-injecting path params, query
params, headers, and a typed JSON body.
"""

from milkha import APIRouter, FastAPI, Request, Response, ok
from milkha.extract import Extracted, JsonBody, PathInt, OptionalQueryInt, HeaderStr
from flare.http import Handler


# A typed JSON request body.
@fieldwise_init
struct NewItem(Copyable, Defaultable, Movable, Deinitable):
    var name: String
    var price: Float64

    def __init__(out self):
        self.name = ""
        self.price = 0.0


# A handler struct whose fields declare the expected inputs.
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
        return ok("user id=" + String(self.id.value) + " auth=" + self.auth.value)


# A handler struct with a typed JSON body field.
@fieldwise_init
struct CreateItem(Copyable, Defaultable, Handler, Movable):
    var body: JsonBody[NewItem]

    def __init__(out self):
        self.body = JsonBody[NewItem]()

    def serve(self, req: Request) raises -> Response:
        return ok(
            "created " + self.body.value.name + " at " + String(self.body.value.price)
        )


def build_app() raises -> APIRouter:
    var app = FastAPI()
    app.get[Extracted[GetUser]]("/users/{id}", Extracted[GetUser]())
    app.post[Extracted[CreateItem]]("/items", Extracted[CreateItem]())
    return app^


def main() raises:
    from flare.http import HttpServer
    from flare.net import SocketAddr

    var app = build_app()
    var srv = HttpServer.bind(SocketAddr.localhost(8080))
    srv.serve(app^, num_workers=2)
