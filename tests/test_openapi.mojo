"""Tests for Milkha OpenAPI spec generation."""

from std.testing import assert_equal, assert_true, TestSuite

from milkha import FastAPI, Request, Response, ok


def health(req: Request) -> Response:
    return ok("ok")


def get_user(req: Request) -> Response:
    return ok("user " + req.param("id"))


def add_routes(app: FastAPI):
    app.get("/", health)
    app.get("/users/{id}", get_user)


def test_openapi_spec_not_empty():
    app = FastAPI()
    add_routes(app)
    spec = app.openapi()
    assert_true(len(spec) > 0)


def test_openapi_contains_openapi_key():
    app = FastAPI()
    add_routes(app)
    spec = app.openapi()
    assert_true(spec.find("openapi") >= 0)


def test_openapi_contains_info():
    app = FastAPI()
    add_routes(app)
    spec = app.openapi()
    assert_true(spec.find("info") >= 0)


def test_openapi_contains_paths():
    app = FastAPI()
    add_routes(app)
    spec = app.openapi()
    assert_true(spec.find("paths") >= 0)


def test_openapi_includes_path():
    app = FastAPI()
    add_routes(app)
    spec = app.openapi()
    assert_true(spec.find("/") >= 0)


def test_openapi_includes_param_path():
    app = FastAPI()
    add_routes(app)
    spec = app.openapi()
    assert_true(spec.find("/users/{id}") >= 0)


def test_openapi_custom_title():
    app = FastAPI()
    add_routes(app)
    spec = app.openapi(title="My API", version="2.0.0")
    assert_true(spec.find("My API") >= 0)


def test_openapi_custom_version():
    app = FastAPI()
    add_routes(app)
    spec = app.openapi(title="My API", version="2.0.0")
    assert_true(spec.find("2.0.0") >= 0)


def main() raises:
    TestSuite.discover_tests[__functions_in_module__]().run()
