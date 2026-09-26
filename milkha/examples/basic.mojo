"""Basic Milkha example: hello world with path parameters.

Run with: `mojo run examples/basic.mojo`
Then visit http://localhost:8080
"""

from milkha import FastAPI, Request, Response, ok
from milkha.extract import PathInt, HeaderStr, Extracted

app = FastAPI()


def home(req: Request) -> Response:
    return ok("Hello, Milkha!")


def get_user(req: Request) -> Response:
    return ok(f"user {req.param('user_id')}")


def get_item(req: Request) -> Response:
    let item_id = PathInt["item_id"].extract(req).value
    let user_agent = HeaderStr["User-Agent"].extract(req).value
    return ok(f"item {item_id.value} for {user_agent.value}")


app.get("/", home)
app.get("/users/{user_id}", get_user)
app.get("/items/{item_id}", get_item)


if __name__ == "__main__":
    from flare.http import HttpServer
    from flare.net import SocketAddr

    # To run: `mojo run examples/basic.mojo`
    srv = HttpServer.bind(SocketAddr.localhost(8080))
    srv.serve(app, num_workers=2)