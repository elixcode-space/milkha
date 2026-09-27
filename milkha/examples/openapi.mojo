"""OpenAPI example: generate a Milkha API spec.

Run with: `mojo run examples/openapi.mojo`
"""

from milkha import FastAPI, Request, Response, ok
from milkha.extract import PathInt, Extracted

app = FastAPI()


def health(req: Request) raises -> Response:
    return ok("ok")


def get_user(req: Request) raises -> Response:
    let id = PathInt["id"].extract(req).value
    return ok(f"user {id.value}")


app.get("/", health)
app.get("/users/{id}", get_user)

if __name__ == "__main__":
    let spec = app.openapi()
    print(spec)