"""Milkha openapi: utilities for OpenAPI spec generation.

Provides helpers to generate and serialize OpenAPI documents from an APIRouter.
"""

from flare.openapi import (
    spec_from_router as _flare_spec_from_router,
    emit_openapi_json,
)
from flare.openapi.spec import OpenApiSpec
from .core import APIRouter


def spec_from_router(
    router: APIRouter, title: String = "Milkha API", version: String = "0.1.1"
) raises -> OpenApiSpec:
    """Build an OpenAPI spec object from a Milkha APIRouter."""
    return _flare_spec_from_router(router.router, title, version)


def spec_to_json(spec: OpenApiSpec) raises -> String:
    """Serialize an OpenAPI spec object to a JSON string."""
    return emit_openapi_json(spec)