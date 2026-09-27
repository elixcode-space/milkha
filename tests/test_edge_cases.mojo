"""Comprehensive tests for Milkha edge cases and error handling."""

from std.testing import assert_equal, assert_true, assert_raises, TestSuite

from milkha import FastAPI, APIRouter, Request, Response, ok, ok_json, Status
from milkha.extract import PathInt, QueryInt


def test_root_path():
    app = FastAPI()

    def root(req: Request) -> Response:
        return ok("root")

    app.get("/", root)
    client = app.test_client()
    assert_equal(client.get("/").status, 200)


def test_deep_nested_path():
    app = FastAPI()

    def deep(req: Request) -> Response:
        return ok(req.url.split("/")[-1])

    app.get("/a/b/c/d", deep)
    client = app.test_client()
    resp = client.get("/a/b/c/d")
    assert_equal(resp.status, 200)


def test_multiple_path_params():
    app = FastAPI()

    def multi(req: Request) -> Response:
        let a = req.param("a")
        let b = req.param("b")
        let c = req.param("c")
        return ok(a + "/" + b + "/" + c)

    app.get("/x/{a}/y/{b}/z/{c}", multi)
    client = app.test_client()
    resp = client.get("/x/1/y/2/z/3")
    assert_equal(resp.status, 200)


def test_post_with_json_body():
    app = FastAPI()

    def create(req: Request) -> Response:
        return ok_json('{"status": "created"}')

    app.post("/items", create)
    client = app.test_client()
    resp = client.post("/items")
    assert_equal(resp.status, 200)


def test_method_not_allowed():
    app = FastAPI()

    def handler(req: Request) -> Response:
        return ok("ok")

    app.get("/only-get", handler)
    client = app.test_client()
    resp = client.post("/only-get")
    assert_true(resp.status >= 400)


def test_route_count_zero():
    app = APIRouter()
    assert_equal(app.route_count(), 0)


def test_include_router_nested():
    outer = APIRouter()
    middle = APIRouter()
    inner = APIRouter()

    def hi(req: Request) -> Response:
        return ok("hi")

    inner.get("/deep", hi)
    middle.include_router("/inner", inner^)
    outer.include_router("/mid", middle^)

    assert_equal(outer.route_count(), 1)

    client = outer.test_client()
    resp = client.get("/mid/inner/deep")
    assert_equal(resp.status, 200)


def test_add_api_route_empty_methods():
    app = APIRouter()

    def handler(req: Request) -> Response:
        return ok("ok")

    app.add_api_route("/empty", handler, [])
    client = app.test_client()
    resp = client.get("/empty")
    assert_equal(resp.status, 404)


def test_openapi_empty_router():
    app = APIRouter()
    spec = app.openapi()
    assert_true(len(spec) > 0)


def test_path_conversion_edge_cases():
    let simple = APIRouter._to_flare_path("/health")
    assert_equal(simple, "/health")

    let empty = APIRouter._to_flare_path("")
    assert_equal(empty, "")

    let root = APIRouter._to_flare_path("/")
    assert_equal(root, "/")

    let only_param = APIRouter._to_flare_path("{id}")
    assert_equal(only_param, ":id")


def test_add_api_route_with_patch():
    app = APIRouter()

    def handler(req: Request) -> Response:
        return ok("patched")

    app.add_api_route("/items", handler, ["PATCH"])
    client = app.test_client()
    resp = client.patch("/items")
    assert_equal(resp.status, 200)


def main() raises:
    TestSuite.discover_tests[__functions_in_module__]().run()
