"""Tests for Milkha OpenAPI spec generation."""

from std.testing import assert_equal, assert_true

from milkha import APIRouter, FastAPI, Request, Response, ok


def health(req: Request) raises -> Response:
    return ok("ok")


def get_user(req: Request) raises -> Response:
    return ok("user " + req.param("id"))


def add_routes(mut app: APIRouter) raises:
    app.get("/", health)
    app.get("/users/{id}", get_user)


def test_openapi_spec_not_empty() raises:
    app = FastAPI()
    add_routes(app)
    spec = app.openapi()
    assert_true(spec.byte_length() > 0)


def test_openapi_contains_openapi_key() raises:
    app = FastAPI()
    add_routes(app)
    spec = app.openapi()
    assert_true(spec.find("openapi") >= 0)


def test_openapi_contains_info() raises:
    app = FastAPI()
    add_routes(app)
    spec = app.openapi()
    assert_true(spec.find("info") >= 0)


def test_openapi_contains_paths() raises:
    app = FastAPI()
    add_routes(app)
    spec = app.openapi()
    assert_true(spec.find("paths") >= 0)


def test_openapi_includes_path() raises:
    app = FastAPI()
    add_routes(app)
    spec = app.openapi()
    assert_true(spec.find("/") >= 0)


def test_openapi_includes_param_path() raises:
    app = FastAPI()
    add_routes(app)
    spec = app.openapi()
    assert_true(spec.find("/users/{id}") >= 0)


def test_openapi_custom_title() raises:
    app = FastAPI()
    add_routes(app)
    spec = app.openapi(title="My API", version="2.0.0")
    assert_true(spec.find("My API") >= 0)


def test_openapi_custom_version() raises:
    app = FastAPI()
    add_routes(app)
    spec = app.openapi(title="My API", version="2.0.0")
    assert_true(spec.find("2.0.0") >= 0)


def main() raises:
    test_openapi_spec_not_empty()
    test_openapi_contains_openapi_key()
    test_openapi_contains_info()
    test_openapi_contains_paths()
    test_openapi_includes_path()
    test_openapi_includes_param_path()
    test_openapi_custom_title()
    test_openapi_custom_version()
