"""Tests for Milkha TestClient: HTTP method dispatch and responses."""

from std.testing import assert_equal, assert_true

from milkha import FastAPI, Request, Response, ok, ok_json


def home(req: Request) raises -> Response:
    return ok("Hello, Milkha!")


def create_item(req: Request) raises -> Response:
    return ok_json('{"message": "created"}')


def test_root_endpoint() raises:
    app = FastAPI()
    app.get("/", home)
    client = app.test_client()
    response = client.get("/")
    assert_equal(response.status, 200)
    assert_equal(response.text(), "Hello, Milkha!")


def test_post_method() raises:
    app = FastAPI()
    app.post("/items", create_item)
    client = app.test_client()
    response = client.post("/items")
    assert_equal(response.status, 200)


def test_put_method() raises:
    def update(req: Request) raises -> Response:
        return ok("updated")

    app = FastAPI()
    app.put("/items/42", update)
    client = app.test_client()
    response = client.put("/items/42")
    assert_equal(response.status, 200)


def test_delete_method() raises:
    def delete(req: Request) raises -> Response:
        return ok("deleted")

    app = FastAPI()
    app.delete("/items/42", delete)
    client = app.test_client()
    response = client.delete("/items/42")
    assert_equal(response.status, 200)


def test_not_found() raises:
    app = FastAPI()
    app.get("/", home)
    client = app.test_client()
    response = client.get("/nonexistent")
    assert_equal(response.status, 404)


def test_ok_helper() raises:
    def health(req: Request) raises -> Response:
        return ok("healthy")

    app = FastAPI()
    app.get("/health", health)
    client = app.test_client()
    response = client.get("/health")
    assert_equal(response.status, 200)
    assert_equal(response.text(), "healthy")


def main() raises:
    test_root_endpoint()
    test_post_method()
    test_put_method()
    test_delete_method()
    test_not_found()
    test_ok_helper()
