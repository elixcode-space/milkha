"""Tests for Milkha extractors (PathInt, HeaderStr, OptionalQueryStr, JsonBody)."""

from std.collections import Optional
from std.testing import assert_equal, assert_true

from milkha import (
    APIRouter,
    Extracted,
    FastAPI,
    Handler,
    Request,
    Response,
    body_bytes,
    ok,
)
from milkha.extract import HeaderStr, JsonBody, OptionalQueryStr, PathInt
from flare.http import HeaderMap


def test_path_int_extractor() raises:
    app = FastAPI()

    def get_item(req: Request) raises -> Response:
        var id = PathInt["item_id"].extract(req).value
        return ok("item " + String(id))

    app.get("/items/{item_id}", get_item)
    var client = app.test_client()
    var response = client.get("/items/42")
    assert_equal(response.status, 200)
    assert_true(response.text().find("42") >= 0)


def test_header_extractor() raises:
    app = FastAPI()

    def get_header(req: Request) raises -> Response:
        var ua = HeaderStr["X-Client"].extract(req).value
        return ok(ua)

    app.get("/headers", get_header)
    var client = app.test_client()
    var headers = HeaderMap()
    try:
        headers.set("X-Client", "milkha")
    except:
        pass
    var response = client.get("/headers", headers^)
    assert_equal(response.status, 200)
    assert_equal(response.text(), "milkha")


def test_optional_query_param() raises:
    app = FastAPI()

    def search(req: Request) raises -> Response:
        var q = OptionalQueryStr["q"].extract(req).value
        if q == Optional[String]():
            return ok("no query")
        return ok("q=" + q.value())

    app.get("/search", search)
    var client = app.test_client()
    var response = client.get("/search?q=mojo")
    assert_equal(response.status, 200)
    assert_true(response.text().find("mojo") >= 0)


def test_optional_query_param_missing() raises:
    app = FastAPI()

    def search(req: Request) raises -> Response:
        var q = OptionalQueryStr["q"].extract(req).value
        if q == Optional[String]():
            return ok("no query")
        return ok("q=" + q.value())

    app.get("/search", search)
    var client = app.test_client()
    var response = client.get("/search")
    assert_equal(response.status, 200)
    assert_equal(response.text(), "no query")


# ── JsonBody[T] ─────────────────────────────────────────────────────────────


@fieldwise_init
struct CreateItem(Copyable, Defaultable, ImplicitlyCopyable, Movable):
    var name: String
    var price: Float64
    var quantity: Int

    def __init__(out self):
        self.name = ""
        self.price = 0.0
        self.quantity = 0


@fieldwise_init
struct CreateUser(Copyable, Defaultable, ImplicitlyCopyable, Movable):
    var name: String
    var address: Address

    def __init__(out self):
        self.name = ""
        self.address = Address()


@fieldwise_init
struct Address(Copyable, Defaultable, ImplicitlyCopyable, Movable):
    var city: String
    var zip: String

    def __init__(out self):
        self.city = ""
        self.zip = ""


@fieldwise_init
struct CreateItemHandler(Copyable, Defaultable, Handler, Movable):
    var body: JsonBody[CreateItem]

    def __init__(out self):
        self.body = JsonBody[CreateItem]()

    def serve(self, req: Request) raises -> Response:
        var item = self.body.value
        return ok("created " + item.name + " at " + String(item.price))


@fieldwise_init
struct CreateUserHandler(Copyable, Defaultable, Handler, Movable):
    var body: JsonBody[CreateUser]
    var id: PathInt["id"]

    def __init__(out self):
        self.body = JsonBody[CreateUser]()
        self.id = PathInt["id"]()

    def serve(self, req: Request) raises -> Response:
        var user = self.body.value
        return ok(
            "user "
            + String(self.id.value)
            + " "
            + user.name
            + " in "
            + user.address.city
        )


def _item_app() raises -> APIRouter:
    var app = FastAPI()
    app.post[Extracted[CreateItemHandler]](
        "/items", Extracted[CreateItemHandler]()
    )
    return app^


def test_json_body_deserialization() raises:
    var app = _item_app()
    var client = app.test_client()
    var response = client.post(
        "/items",
        body_bytes('{"name": "widget", "price": 9.5, "quantity": 3}'),
    )
    assert_equal(response.status, 200)
    assert_equal(response.text(), "created widget at 9.5")


def test_json_body_ignores_unknown_keys() raises:
    var app = _item_app()
    var client = app.test_client()
    var response = client.post(
        "/items",
        body_bytes(
            '{"name": "bolt", "price": 1.25, "quantity": 10, "extra": true}'
        ),
    )
    assert_equal(response.status, 200)
    assert_equal(response.text(), "created bolt at 1.25")


def test_json_body_nested_struct() raises:
    var app = FastAPI()
    app.post[Extracted[CreateUserHandler]](
        "/users/{id}", Extracted[CreateUserHandler]()
    )
    var client = app.test_client()
    var response = client.post(
        "/users/7",
        body_bytes(
            '{"name": "Ada", "address": {"city": "London", "zip": "NW1"}}'
        ),
    )
    assert_equal(response.status, 200)
    assert_equal(response.text(), "user 7 Ada in London")


def test_json_body_mixed_with_path_extractor() raises:
    var app = FastAPI()
    app.post[Extracted[CreateUserHandler]](
        "/users/{id}", Extracted[CreateUserHandler]()
    )
    var client = app.test_client()
    # The path parameter is present, so a malformed body still yields 400.
    var response = client.post("/users/7", body_bytes("{"))
    assert_equal(response.status, 400)


def test_json_body_missing_field_is_bad_request() raises:
    var app = _item_app()
    var client = app.test_client()
    var response = client.post("/items", body_bytes('{"name": "widget"}'))
    assert_equal(response.status, 400)


def test_json_body_invalid_json_is_bad_request() raises:
    var app = _item_app()
    var client = app.test_client()
    var response = client.post("/items", body_bytes("not json at all"))
    assert_equal(response.status, 400)


def test_json_body_empty_body_is_bad_request() raises:
    var app = _item_app()
    var client = app.test_client()
    var response = client.post("/items", body_bytes(""))
    assert_equal(response.status, 400)


def test_json_body_type_mismatch_is_bad_request() raises:
    var app = _item_app()
    var client = app.test_client()
    var response = client.post(
        "/items",
        body_bytes('{"name": 5, "price": "free", "quantity": "many"}'),
    )
    assert_equal(response.status, 400)


def test_json_body_value_constructor() raises:
    var app = FastAPI()

    def echo(req: Request) raises -> Response:
        var item = JsonBody[CreateItem].extract(req).value
        return ok(item.name)

    app.post("/items", echo)
    var client = app.test_client()
    var response = client.post(
        "/items", body_bytes('{"name": "gear", "price": 2.0, "quantity": 7}')
    )
    assert_equal(response.status, 200)
    assert_equal(response.text(), "gear")


def test_json_body_defaults_before_extraction() raises:
    var body = JsonBody[CreateItem]()
    assert_equal(body.value.name, "")
    assert_equal(body.value.quantity, 0)


def main() raises:
    test_path_int_extractor()
    test_header_extractor()
    test_optional_query_param()
    test_optional_query_param_missing()
    test_json_body_deserialization()
    test_json_body_ignores_unknown_keys()
    test_json_body_nested_struct()
    test_json_body_mixed_with_path_extractor()
    test_json_body_missing_field_is_bad_request()
    test_json_body_invalid_json_is_bad_request()
    test_json_body_empty_body_is_bad_request()
    test_json_body_type_mismatch_is_bad_request()
    test_json_body_value_constructor()
    test_json_body_defaults_before_extraction()
