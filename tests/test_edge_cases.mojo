"""Comprehensive tests for Milkha edge cases and error handling."""

from std.testing import assert_equal, assert_true, assert_raises

from milkha import FastAPI, APIRouter, Request, Response, ok, ok_json


def test_root_path() raises:
    app = FastAPI()

    def root(req: Request) raises -> Response:
        return ok("root")

    app.get("/", root)
    client = app.test_client()
    assert_equal(client.get("/").status, 200)


def test_deep_nested_path() raises:
    app = FastAPI()

    def deep(req: Request) raises -> Response:
        return ok("nested")

    app.get("/a/b/c/d", deep)
    client = app.test_client()
    resp = client.get("/a/b/c/d")
    assert_equal(resp.status, 200)


def test_multiple_path_params() raises:
    app = FastAPI()

    def multi(req: Request) raises -> Response:
        var a = req.param("a")
        var b = req.param("b")
        var c = req.param("c")
        return ok(a + "/" + b + "/" + c)

    app.get("/x/{a}/y/{b}/z/{c}", multi)
    client = app.test_client()
    resp = client.get("/x/1/y/2/z/3")
    assert_equal(resp.status, 200)


def test_post_with_json_body() raises:
    app = FastAPI()

    def create(req: Request) raises -> Response:
        return ok_json('{"status": "created"}')

    app.post("/items", create)
    client = app.test_client()
    resp = client.post("/items")
    assert_equal(resp.status, 200)


def test_method_not_allowed() raises:
    app = FastAPI()

    def handler(req: Request) raises -> Response:
        return ok("ok")

    app.get("/only-get", handler)
    client = app.test_client()
    resp = client.post("/only-get")
    assert_true(resp.status >= 400)


def test_route_count_zero() raises:
    app = APIRouter()
    assert_equal(app.route_count(), 0)


def test_include_router_nested() raises:
    outer = APIRouter()
    middle = APIRouter()
    inner = APIRouter()

    def hi(req: Request) raises -> Response:
        return ok("hi")

    inner.get("/deep", hi)
    middle.include_router("/inner", inner^)
    outer.include_router("/mid", middle^)

    assert_equal(outer.route_count(), 1)

    client = outer.test_client()
    resp = client.get("/mid/inner/deep")
    assert_equal(resp.status, 200)


def test_add_api_route_empty_methods() raises:
    app = APIRouter()

    def handler(req: Request) raises -> Response:
        return ok("ok")

    app.add_api_route("/empty", handler, [])
    client = app.test_client()
    resp = client.get("/empty")
    assert_equal(resp.status, 404)


def test_openapi_empty_router() raises:
    app = APIRouter()
    spec = app.openapi()
    assert_true(spec.byte_length() > 0)


def test_path_conversion_edge_cases() raises:
    var simple = APIRouter._to_flare_path("/health")
    assert_equal(simple, "/health")

    var empty = APIRouter._to_flare_path("")
    assert_equal(empty, "")

    var root = APIRouter._to_flare_path("/")
    assert_equal(root, "/")

    var only_param = APIRouter._to_flare_path("{id}")
    assert_equal(only_param, ":id")


def test_add_api_route_with_patch() raises:
    app = APIRouter()

    def handler(req: Request) raises -> Response:
        return ok("patched")

    app.add_api_route("/items", handler, ["PATCH"])
    client = app.test_client()
    resp = client.patch("/items")
    assert_equal(resp.status, 200)


def main() raises:
    test_root_path()
    test_deep_nested_path()
    test_multiple_path_params()
    test_post_with_json_body()
    test_method_not_allowed()
    test_route_count_zero()
    test_include_router_nested()
    test_add_api_route_empty_methods()
    test_openapi_empty_router()
    test_path_conversion_edge_cases()
    test_add_api_route_with_patch()
