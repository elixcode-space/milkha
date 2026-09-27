"""Milkha extract: Dependency injection / extractor re‑exports.

Re‑exports Flare's typed extractors (PathInt, QueryInt, HeaderStr, Json, Cookies,
Form, etc.) and the ``Extracted`` reflective injection wrapper so users can write
``r.get("/users/:id", Extracted[MyHandler]())````, plus Milkha's own
``JsonBody[T]`` typed JSON request‑body extractor.
"""

from flare.http import Handler, Request
from flare.http.extract import (
    Extractor,
    PathInt,
    PathStr,
    PathFloat,
    PathBool,
    QueryInt,
    QueryStr,
    QueryFloat,
    QueryBool,
    OptionalQueryInt,
    OptionalQueryStr,
    OptionalQueryFloat,
    OptionalQueryBool,
    HeaderInt,
    HeaderStr,
    HeaderFloat,
    HeaderBool,
    OptionalHeaderInt,
    OptionalHeaderStr,
    OptionalHeaderFloat,
    OptionalHeaderBool,
    Peer,
    BodyBytes,
    BodyText,
    Json,
    Cookies,
    Form,
    Multipart,
    Extracted,
)
from json import deserialize_json


@fieldwise_init
struct JsonBody[T: Copyable & Defaultable & Movable & Deinitable](
    Copyable, Defaultable, Extractor, Movable
):
    """Typed JSON request‑body extractor, the analogue of a FastAPI/Pydantic body model.

    Declares that the request body is a JSON object deserialized into ``T``.
    ``T`` is any Mojo struct whose fields are ``String`` / ``Int`` / ``Float64``
    / ``Bool`` / ``Optional[...]`` / ``List[...]`` (or another such struct);
    JSON keys map to field names, and the mapping is done by compile‑time
    reflection, so no per‑field code is written.

    Value constructor inside a handler body::

        def create_item(req: Request) raises -> Response:
            var item = JsonBody[CreateItem].extract(req).value
            return ok(item.name)

    Auto‑injection as a handler field, so extractor failures become a
    **400 Bad Request** instead of a 500::

        @fieldwise_init
        struct CreateItemHandler(Copyable, Defaultable, Handler, Movable):
            var body: JsonBody[CreateItem]

            def __init__(out self):
                self.body = JsonBody[CreateItem]()

            def serve(self, req: Request) raises -> Response:
                return ok("created " + self.body.value.name)

        app.post[Extracted[CreateItemHandler]](
            "/items", Extracted[CreateItemHandler]()
        )

    Args:
        value: The deserialized body. Default-constructed until ``apply``.

    Raises:
        Error on an empty body, malformed JSON, a missing field, or a field
        whose JSON type does not match the struct field type.
    """

    var value: Self.T

    def __init__(out self):
        self.value = Self.T()

    def apply(mut self, req: Request) raises:
        if len(req.body) == 0:
            raise Error("missing JSON body")
        self.value = deserialize_json[Self.T](req.text())

    @staticmethod
    def extract(req: Request) raises -> Self:
        var out = Self()
        out.apply(req)
        return out^
