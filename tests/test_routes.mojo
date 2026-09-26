"""Tests for Milkha add_api_route and include_router."""

from std.testing import assert_equal, assert_true, assert_raises, TestSuite

from milkha import FastAPI, Request, Response, ok
from milkha.core import APIRouter


def handler(req: Request) -> Response:
    return ok("ok")


def test_add_api_route_single_method():
    app = APIRouter()
    app.add_api_route("/items", handler, ["GET"])
    client = app.test_client()
    response = client.get("/items")
    assert_equal(response.status, 200)


def test_add_api_route_multiple_methods():
    app = APIRouter()
    app.add_api_route("/items", handler, ["GET", "POST"])
    client = app.test_client()
    assert_equal(client.get("/items").status, 200)
    assert_equal(client.post("/items").status, 200)


def test_add_api_route_all_methods():
    app = APIRouter()
    app.add_api_route("/items", handler, ["GET", "POST", "PUT", "DELETE", "PATCH"])
    client = app.test_client()
    assert_equal(client.get("/items").status, 200)
    assert_equal(client.post("/items").status, 200)
    assert_equal(client.put("/items").status, 200)
    assert_equal(client.delete("/items").status, 200)
    assert_equal(client.patch("/items").status, 200)


def test_add_api_route_unsupported_method():
    app = APIRouter()
    with assert_raises():
        app.add_api_route("/items", handler, ["BOGUS"])


def test_include_router():
    main_app = APIRouter()
    sub_app = APIRouter()
    sub_app.get("/users", handler)
    main_app.include_router("/api/v1", sub_app^)
    client = main_app.test_client()
    response = client.get("/api/v1/users")
    assert_equal(response.status, 200)


def test_include_router_with_path_param():
    main_app = APIRouter()
    sub_app = APIRouter()
    sub_app.get("/items/{id}", handler)
    main_app.include_router("/api{v}", sub_app^)
    client = main_app.test_client()
    response = client.get("/api1/items/42")
    assert_equal(response.status, 200)


def test_route_count_after_mount():
    main_app = APIRouter()
    sub_app = APIRouter()
    sub_app.get("/users", handler)
    sub_app.get("/items", handler)
    main_app.include_router("/api", sub_app^)
    assert_equal(main_app.route_count(), 2)


def main() raises:
    TestSuite.discover_tests[__functions_in_module__]().run()
