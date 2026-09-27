"""Tests for Milkha routing, path-template conversion, and route metadata."""

from std.testing import assert_equal, assert_true, TestSuite

from milkha import FastAPI, APIRouter, Route, Request, Response, ok


def home(req: Request) raises -> Response:
    return ok("Hello, Milkha!")


def echo_user(req: Request) raises -> Response:
    return ok("user " + req.param("user_id"))


def make_app() -> APIRouter:
    app = FastAPI()
    app.get("/", home)
    app.get("/users/{user_id}", echo_user)
    return app


def test_route_count():
    app = make_app()
    assert_equal(app.route_count(), 2)


def test_flare_path_conversion():
    var out = APIRouter._to_flare_path("/users/{user_id}")
    assert_equal(out, "/users/:user_id")


def test_flare_path_conversion_multiple_params():
    var out = APIRouter._to_flare_path("/orgs/{org}/repos/{repo}")
    assert_equal(out, "/orgs/:org/repos/:repo")


def test_flare_path_conversion_no_params():
    var out = APIRouter._to_flare_path("/health")
    assert_equal(out, "/health")


def test_route_metadata():
    app = make_app()
    r0 = app.route(0)
    assert_equal(r0.method, "GET")
    assert_equal(r0.template, "/")

    r1 = app.route(1)
    assert_equal(r1.method, "GET")
    assert_equal(r1.template, "/users/{user_id}")


def test_fastapi_template_noop():
    let tmpl = "/users/{id}"
    let result = APIRouter._to_fastapi_template(tmpl)
    assert_equal(result, tmpl)


def main() raises:
    TestSuite.discover_tests[__functions_in_module__]().run()
