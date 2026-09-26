"""Typed extractors example: using Extracted and Flare extractors.

Demonstrates Extracted[H] for auto‑injecting path params, query
params, headers, and body fields.
"""

from milkha import FastAPI, Request, Response, ok
from milkha.extract import Extracted, PathInt, OptionalQueryInt, HeaderStr, Json

app = FastAPI()


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
        let auth_str = self.auth.value
        return ok(f"user={self.id.value} page={self.page.value} auth={auth_str}")


# A JSON body extractor struct.
@fieldwise_init
struct CreateItem(Copyable, Defaultable, Handler, Movable):
    var name: String
    var price: Float64

    def __init__(out self):
        self.name = ""
        self.price = 0.0

    def serve(self, req: Request) raises -> Response:
        let body = Json.extract(req).value
        return ok(f"created {self.name} at {self.price}")


app.get[Extracted[GetUser]]("/users/{id}", Extracted[GetUser]())
app.post[Extracted[CreateItem]]("/items", Extracted[CreateItem]())


if __name__ == "__main__":
    from flare.http import HttpServer
    from flare.net import SocketAddr

    srv = HttpServer.bind(SocketAddr.localhost(8080))
    srv.serve(app, num_workers=2)