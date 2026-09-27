"""Milkha test: In-process test client for Milkha routers.

Wraps Flare's TestClient to provide a familiar FastAPI-like testing surface.
"""

from flare.http import Handler, Router
from flare.testing import TestClient as FlareTestClient
from .core import APIRouter


comptime TestClient[H: Handler] = FlareTestClient[H]


def test_client(router: APIRouter) -> FlareTestClient[Router]:
    """Create a test client for the given APIRouter."""
    return router.test_client()


def body_bytes(text: String) -> List[UInt8]:
    """Encode ``text`` into the ``List[UInt8]`` a test client expects as a body.

    Flare's ``TestClient.post(path, body)`` takes raw bytes, so JSON payloads
    need one conversion step::

        var response = client.post("/items", json_body('{"name": "widget"}'))

    Args:
        text: The request body, e.g. a JSON document.

    Returns:
        The UTF-8 bytes of ``text``.
    """
    var out = List[UInt8](capacity=text.byte_length())
    for b in text.as_bytes():
        out.append(b)
    return out^
