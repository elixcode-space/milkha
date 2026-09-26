"""Milkha openapi: utilities for OpenAPI spec generation.

Provides helpers to generate and serialize OpenAPI documents from an APIRouter.
"""

from flare.openapi import spec_from_router, emit_openapi_json


def spec_from_router(
    router, title: String = "Milkha API", version: String = "0.1.0"
) raises:
    """Build an OpenAPI spec object from a Milkha APIRouter."""
    return spec_from_router(router.router, title, version)


def spec_to_json(spec) raises -> String:
    """Serialize an OpenAPI spec object to a JSON string."""
    return emit_openapi_json(spec)