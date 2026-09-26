"""Milkha: A FastAPI-compatible web framework for Mojo built on Flare.

This package provides a drop-in replacement for FastAPI in Mojo, using Flare's
high-performance HTTP runtime while exposing FastAPI-like API surface.

Public API:
- FastAPI() -> APIRouter: Creates the main router instance
- APIRouter: Core routing object with .get(), .post(), etc.
- Request, Response: HTTP request/response types
- Extracted[T]: Dependency injection/extractor wrapper
- Route: Route metadata type
"""

from flare.prelude import *  # Request, Response, Router, HttpServer, ok, etc.
from flare.http import (
    Handler,
    Extracted,
    PathInt,
    PathStr,
    QueryInt,
    QueryStr,
    HeaderStr,
    Form,
    Json,
    Cookies,
)
from .core import APIRouter, Route
from .extract import Extracted as Extracted
from .openapi import spec_from_router
from .test import TestClient

# Public exports
__all__ = [
    "FastAPI",
    "APIRouter",
    "Request",
    "Response",
    "Route",
    "Extracted",
    "ok",
    "ok_json",
    "spec_from_router",
    "TestClient",
]

def FastAPI() -> APIRouter:
    """Create a new APIRouter instance (FastAPI compatibility wrapper)."""
    return APIRouter()
