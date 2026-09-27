"""Full CRUD example: a REST API for managing items.

Demonstrates:
- Path parameters with PathInt extractor
- Query parameters with OptionalQueryInt
- JSON responses with ok_json
- POST, GET, PUT, DELETE methods
- OpenAPI spec generation
- In-process TestClient usage

Run with: `mojo run milkha/examples/crud.mojo`
Then visit http://localhost:8080/openapi.json
"""

from milkha import FastAPI, Request, Response, ok, ok_json
from milkha.extract import PathInt, OptionalQueryInt


app = FastAPI()


def list_items(req: Request) raises -> Response:
    """GET /items - List all items with pagination."""
    let page = OptionalQueryInt["page"].extract(req).value
    let per_page = OptionalQueryInt["per_page"].extract(req).value
    return ok_json('{"items": [], "page": 0}')


def create_item(req: Request) raises -> Response:
    """POST /items - Create a new item."""
    return ok_json('{"id": 1, "name": "new_item", "status": "created"}')


def get_item(req: Request) raises -> Response:
    """GET /items/{item_id} - Get a specific item."""
    let id = PathInt["item_id"].extract(req).value
    return ok_json('{"id": "' + String(id.value) + '", "name": "item"}')


def update_item(req: Request) raises -> Response:
    """PUT /items/{item_id} - Update an item."""
    let id = PathInt["item_id"].extract(req).value
    return ok_json('{"id": "' + String(id.value) + '", "updated": true}')


def delete_item(req: Request) raises -> Response:
    """DELETE /items/{item_id} - Delete an item."""
    let id = PathInt["item_id"].extract(req).value
    return ok_json('{"id": "' + String(id.value) + '", "deleted": true}')


# Register routes
app.get("/items", list_items)
app.post("/items", create_item)
app.get("/items/{item_id}", get_item)
app.put("/items/{item_id}", update_item)
app.delete("/items/{item_id}", delete_item)


if __name__ == "__main__":
    # Run introspection and TestClient demo
    print("=" * 60)
    print("CRUD Example - Route Summary")
    print("=" * 60)

    let count = app.route_count()
    print(f"Registered {count} routes:")

    for i in range(count):
        var route = app.route(i)
        print(f"  [{route.method}] {route.template}")

    print()

    # Generate OpenAPI spec
    let spec = app.openapi(title="CRUD API", version="1.0.0")
    print("OpenAPI spec generated (length: " + String(len(spec)) + " bytes)")
    print()

    # Test with TestClient
    client = app.test_client()

    print("Testing endpoints via TestClient:")

    # GET /items
    let list_resp = client.get("/items")
    print(f"  GET /items -> {list_resp.status}: {list_resp.text()}")

    # POST /items
    let create_resp = client.post("/items")
    print(f"  POST /items -> {create_resp.status}: {create_resp.text()}")

    # GET /items/42
    let get_resp = client.get("/items/42")
    print(f"  GET /items/42 -> {get_resp.status}: {get_resp.text()}")

    # PUT /items/42
    let put_resp = client.put("/items/42")
    print(f"  PUT /items/42 -> {put_resp.status}: {put_resp.text()}")

    # DELETE /items/42
    let del_resp = client.delete("/items/42")
    print(f"  DELETE /items/42 -> {del_resp.status}: {del_resp.text()}")

    print()
    print("=" * 60)
    print("To run the server:")
    print("  from flare.http import HttpServer")
    print("  from flare.net import SocketAddr")
    print("  srv = HttpServer.bind(SocketAddr.localhost(8080))")
    print("  srv.serve(app, num_workers=2)")
    print("=" * 60)
