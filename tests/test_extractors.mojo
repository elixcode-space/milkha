"""Tests for Milkha extractors (PathInt, HeaderStr, QueryStr)."""

from std.testing import assert_equal, assert_true, TestSuite

from milkha import FastAPI, Request, Response, ok
from milkha.extract import PathInt, HeaderStr, OptionalQueryStr


def test_path_int_extractor():
    app = FastAPI()

    def get_item(req: Request) raises -> Response:
        let id = PathInt["item_id"].extract(req).value
        return ok("item " + String(id.value))

    app.get("/items/{item_id}", get_item)
    client = app.test_client()
    response = client.get("/items/42")
    assert_equal(response.status, 200)
    assert_true(response.text().find("42") >= 0)


def test_header_extractor():
    app = FastAPI()

    def get_header(req: Request) raises -> Response:
        let ua = HeaderStr["User-Agent"].extract(req).value
        return ok(ua.value)

    app.get("/headers", get_header)
    client = app.test_client()
    response = client.get("/headers")
    assert_equal(response.status, 200)


def test_optional_query_param():
    app = FastAPI()

    def search(req: Request) raises -> Response:
        let q = OptionalQueryStr["q"].extract(req).value
        let val = q.value
        if val.byte_length() > 0:
            return ok("q=" + q.value)
        return ok("no query")

    app.get("/search", search)
    client = app.test_client()
    response = client.get("/search?q=mojo")
    assert_equal(response.status, 200)
    assert_true(response.text().find("mojo") >= 0)


def test_optional_query_param_missing():
    app = FastAPI()

    def search(req: Request) raises -> Response:
        let q = OptionalQueryStr["q"].extract(req).value
        let val = q.value
        if val.byte_length() > 0:
            return ok("q=" + q.value)
        return ok("no query")

    app.get("/search", search)
    client = app.test_client()
    response = client.get("/search")
    assert_equal(response.status, 200)
    assert_equal(response.text(), "no query")


def main() raises:
    TestSuite.discover_tests[__functions_in_module__]().run()
