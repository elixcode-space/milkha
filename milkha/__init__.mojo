"""Milkha: A FastAPI-compatible web framework for Mojo built on Flare.

This package provides a drop-in replacement for FastAPI in Mojo, using Flare's
high-performance HTTP runtime while exposing FastAPI-like API surface.

Public API:
- FastAPI() -> APIRouter: Creates the main router instance
- APIRouter: Core routing object with .get(), .post(), etc.
- Request, Response: HTTP request/response types
- Extracted[T]: Dependency injection/extractor wrapper
- Route: Route metadata type
- Status/StatusCode: HTTP status code constants
- Method: HTTP method constants
"""

from flare.prelude import *  # Request, Response, Router, HttpServer, ok, etc.
from flare.http import (
    Handler,
    Method,
    Status,
)
from .core import APIRouter, Route
from .extract import (
    Extracted,
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
)
from .openapi import spec_from_router
from .test import TestClient

# Re-export Status constants for FastAPI compatibility
StatusCode = Status

# Public exports
__all__ = [
    "FastAPI",
    "APIRouter",
    "Request",
    "Response",
    "Route",
    "Extracted",
    "Extractor",
    "PathInt",
    "PathStr",
    "PathFloat",
    "PathBool",
    "QueryInt",
    "QueryStr",
    "QueryFloat",
    "QueryBool",
    "OptionalQueryInt",
    "OptionalQueryStr",
    "OptionalQueryFloat",
    "OptionalQueryBool",
    "HeaderInt",
    "HeaderStr",
    "HeaderFloat",
    "HeaderBool",
    "OptionalHeaderInt",
    "OptionalHeaderStr",
    "OptionalHeaderFloat",
    "OptionalHeaderBool",
    "Peer",
    "BodyBytes",
    "BodyText",
    "Json",
    "Cookies",
    "Form",
    "Multipart",
    "Method",
    "Status",
    "StatusCode",
    "ok",
    "ok_json",
    "spec_from_router",
    "TestClient",
]

def FastAPI() -> APIRouter:
    """Create a new APIRouter instance (FastAPI compatibility wrapper)."""
    return APIRouter()
