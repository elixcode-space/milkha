"""Tests for Milkha TestClient: HTTP method dispatch and responses."""

from std.testing import assert_equal, assert_true, TestSuite

from milkha import FastAPI, Request, Response, ok, ok_json


def home(req: Request) -> Response:
    return ok("Hello, Milkha!")


def create_item(req: Request) -> Response:
    return ok_json('{"message": "created"}')


def test_root_endpoint():
    app = FastAPI()
    app.get("/", home)
    client = app.test_client()
    response = client.get("/")
    assert_equal(response.status, 200)
    assert_equal(response.text(), "Hello, Milkha!")


def test_post_method():
    app = FastAPI()
    app.post("/items", create_item)
    client = app.test_client()
    response = client.post("/items")
    assert_equal(response.status, 200)


def test_put_method():
    def update(req: Request) -> Response:
        return ok("updated")

    app = FastAPI()
    app.put("/items/42", update)
    client = app.test_client()
    response = client.put("/items/42")
    assert_equal(response.status, 200)


def test_delete_method():
    def delete(req: Request) -> Response:
        return ok("deleted")

    app = FastAPI()
    app.delete("/items/42", delete)
    client = app.test_client()
    response = client.delete("/items/42")
    assert_equal(response.status, 200)


def test_not_found():
    app = FastAPI()
    app.get("/", home)
    client = app.test_client()
    response = client.get("/nonexistent")
    assert_equal(response.status, 404)


def test_ok_helper():
    def health(req: Request) -> Response:
        return ok("healthy")

    app = FastAPI()
    app.get("/health", health)
    client = app.test_client()
    response = client.get("/health")
    assert_equal(response.status, 200)
    assert_equal(response.text(), "healthy")


def main() raises:
    TestSuite.discover_tests[__functions_in_module__]().run()
