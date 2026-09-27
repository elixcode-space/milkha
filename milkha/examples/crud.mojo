"""Full CRUD example: a REST API for managing items.

Demonstrates:
- Path parameters with PathInt extractor
- Query parameters with OptionalQueryInt
- JSON responses with ok_json
- POST, GET, PUT, DELETE methods
- OpenAPI spec generation
- In-process TestClient usage

Run with: `pixi run example crud`
"""

from milkha import APIRouter, FastAPI, Request, Response, ok_json
from milkha.extract import PathInt, OptionalQueryInt


def list_items(req: Request) raises -> Response:
    """GET /items - List all items with pagination."""
    var page = OptionalQueryInt["page"].extract(req).value
    var per_page = OptionalQueryInt["per_page"].extract(req).value
    _ = page
    _ = per_page
    return ok_json('{"items": [], "page": 0}')


def create_item(req: Request) raises -> Response:
    """POST /items - Create a new item."""
    return ok_json('{"id": 1, "name": "new_item", "status": "created"}')


def get_item(req: Request) raises -> Response:
    """GET /items/{item_id} - Get a specific item."""
    var id = PathInt["item_id"].extract(req).value
    return ok_json('{"id": "' + String(id) + '", "name": "item"}')


def update_item(req: Request) raises -> Response:
    """PUT /items/{item_id} - Update an item."""
    var id = PathInt["item_id"].extract(req).value
    return ok_json('{"id": "' + String(id) + '", "updated": true}')


def delete_item(req: Request) raises -> Response:
    """DELETE /items/{item_id} - Delete an item."""
    var id = PathInt["item_id"].extract(req).value
    return ok_json('{"id": "' + String(id) + '", "deleted": true}')


def build_app() raises -> APIRouter:
    var app = FastAPI()
    app.get("/items", list_items)
    app.post("/items", create_item)
    app.get("/items/{item_id}", get_item)
    app.put("/items/{item_id}", update_item)
    app.delete("/items/{item_id}", delete_item)
    return app^


def main() raises:
    app = build_app()

    print("=" * 60)
    print("CRUD Example - Route Summary")
    print("=" * 60)

    var count = app.route_count()
    print("Registered " + String(count) + " routes:")

    for i in range(count):
        var route = app.route(i)
        print("  [" + route.method + "] " + route.template)

    print()

    # Generate OpenAPI spec
    var spec = app.openapi(title="CRUD API", version="1.0.0")
    print("OpenAPI spec generated (length: " + String(spec.byte_length()) + " bytes)")
    print()

    # Test with TestClient
    var client = app.test_client()

    print("Testing endpoints via TestClient:")

    var list_resp = client.get("/items")
    print("  GET /items -> " + String(list_resp.status) + ": " + list_resp.text())

    var create_resp = client.post("/items")
    print("  POST /items -> " + String(create_resp.status) + ": " + create_resp.text())

    var get_resp = client.get("/items/42")
    print("  GET /items/42 -> " + String(get_resp.status) + ": " + get_resp.text())

    var put_resp = client.put("/items/42")
    print("  PUT /items/42 -> " + String(put_resp.status) + ": " + put_resp.text())

    var del_resp = client.delete("/items/42")
    print("  DELETE /items/42 -> " + String(del_resp.status) + ": " + del_resp.text())

    print()
    print("=" * 60)
    print("To run the server:")
    print("  from flare.http import HttpServer")
    print("  from flare.net import SocketAddr")
    print("  srv = HttpServer.bind(SocketAddr.localhost(8080))")
    print("  srv.serve(app^, num_workers=2)")
    print("=" * 60)
