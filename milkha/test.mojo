"""Milkha test: In-process test client for Milkha routers.

Wraps Flare's TestClient to provide a familiar FastAPI-like testing surface.
"""

from flare.http import Router
from flare.testing import TestClient as FlareTestClient
from .core import APIRouter


type TestClient[H] = FlareTestClient[H]


def test_client(router: APIRouter) -> FlareTestClient[Router]:
    """Create a test client for the given APIRouter."""
    return router.test_client()