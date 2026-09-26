"""Milkha core: FastAPI-compatible router wrapping Flare's Router.

Provides APIRouter with FastAPI-style method names, path-template conversion
({param} -> :param), route metadata, OpenAPI generation, and a test client.
"""

from flare.http import Router, Request, Response, ok, ok_json, Method, Status, Handler
from flare.openapi import spec_from_router, emit_openapi_json
from flare.testing import TestClient as FlareTestClient
from flare.http.extract import Extracted


struct Route(Movable):
    """Minimal route metadata (method, FastAPI template, path-param names)."""
    var method: String
    var template: String   # FastAPI-style {param} template
    var path_params: List[String]


struct APIRouter(Copyable, Handler, Movable):
    """FastAPI-compatible router backed by Flare's Router.

    Public API mirrors FastAPI:
        - get(path, handler), post(...), put(...), delete(...), patch(...)
        - include_router(prefix, sub_router)
        - add_api_route(path, handler, methods, ...)
        - openapi() -> JSON string
        - test_client() -> TestClient for in-process testing

    Internally stores a Flare Router and converts FastAPI `{param}` syntax
    to Flare's `:param` syntax at registration time.
    """

    var router: Router

    def __init__(out self):
        self.router = Router()

    # ── Path-template conversion (FastAPI {param} -> Flare :param) ───────────

    @staticmethod
    def _to_flare_path(path: String) -> String:
        """Convert FastAPI `{param}` to Flare `:param`."""
        var out = String(capacity=path.byte_length())
        var p = path.unsafe_ptr()
        var n = path.byte_length()
        var i = 0
        while i < n:
            var c = p[i]
            if c == UInt8(ord('{')):
                out += ":"
                i += 1
                while i < n and p[i] != UInt8(ord('}')):
                    out += chr(Int(p[i]))
                    i += 1
                if i < n and p[i] == UInt8(ord('}')):
                    i += 1
            else:
                out += chr(Int(c))
                i += 1
        return out^

    # ── HTTP method registration (def-function overloads) ────────────────────

    def get(mut self, path: String, handler: def(Request) raises thin -> Response) raises:
        self.router.get(self._to_flare_path(path), handler)

    def post(mut self, path: String, handler: def(Request) raises thin -> Response) raises:
        self.router.post(self._to_flare_path(path), handler)

    def put(mut self, path: String, handler: def(Request) raises thin -> Response) raises:
        self.router.put(self._to_flare_path(path), handler)

    def delete(mut self, path: String, handler: def(Request) raises thin -> Response) raises:
        self.router.delete(self._to_flare_path(path), handler)

    def patch(mut self, path: String, handler: def(Request) raises thin -> Response) raises:
        self.router.patch(self._to_flare_path(path), handler)

    def head(mut self, path: String, handler: def(Request) raises thin -> Response) raises:
        self.router.head(self._to_flare_path(path), handler)

    def options(mut self, path: String, handler: def(Request) raises thin -> Response) raises:
        self.router.options(self._to_flare_path(path), handler)

    # ── Handler-struct overloads (Extracted[H] etc.) ────────────────────────

    def get[H: Handler & Copyable & Movable](
        mut self, path: String, var handler: H
    ) raises:
        self.router.get[H](self._to_flare_path(path), handler^)

    def post[H: Handler & Copyable & Movable](
        mut self, path: String, var handler: H
    ) raises:
        self.router.post[H](self._to_flare_path(path), handler^)

    def put[H: Handler & Copyable & Movable](
        mut self, path: String, var handler: H
    ) raises:
        self.router.put[H](self._to_flare_path(path), handler^)

    def delete[H: Handler & Copyable & Movable](
        mut self, path: String, var handler: H
    ) raises:
        self.router.delete[H](self._to_flare_path(path), handler^)

    def patch[H: Handler & Copyable & Movable](
        mut self, path: String, var handler: H
    ) raises:
        self.router.patch[H](self._to_flare_path(path), handler^)

    def head[H: Handler & Copyable & Movable](
        mut self, path: String, var handler: H
    ) raises:
        self.router.head[H](self._to_flare_path(path), handler^)

    def options[H: Handler & Copyable & Movable](
        mut self, path: String, var handler: H
    ) raises:
        self.router.options[H](self._to_flare_path(path), handler^)

    # ── Sub-router mounting ──────────────────────────────────────────────────

    def include_router(mut self, prefix: String, var sub: APIRouter) raises:
        """Mount another APIRouter under a literal prefix.

        The prefix may use FastAPI `{param}` syntax; it is converted to
        Flare's `:param` before delegating to the inner Router.mount.
        """
        self.router.mount(self._to_flare_path(prefix), sub.router)

    # ── Low-level route registration ────────────────────────────────────────

    def add_api_route(
        mut self,
        path: String,
        handler: def(Request) raises thin -> Response,
        methods: List[String],
    ) raises:
        """Register a handler for an arbitrary set of HTTP methods.

        Mirrors FastAPI's `router.add_api_route`.
        """
        var flare_path = self._to_flare_path(path)
        for m in methods:
            if m == "GET":
                self.router.get(flare_path, handler)
            elif m == "POST":
                self.router.post(flare_path, handler)
            elif m == "PUT":
                self.router.put(flare_path, handler)
            elif m == "DELETE":
                self.router.delete(flare_path, handler)
            elif m == "PATCH":
                self.router.patch(flare_path, handler)
            elif m == "HEAD":
                self.router.head(flare_path, handler)
            elif m == "OPTIONS":
                self.router.options(flare_path, handler)
            else:
                raise Error("unsupported HTTP method: " + m)

    # ── Route introspection (OpenAPI / docs) ─────────────────────────────────

    def route_count(self) -> Int:
        return self.router.route_count()

    def route(self, i: Int) -> Route:
        """Return route metadata for the i-th registered route."""
        var tmpl = self.router.route_openapi_template(i)
        # Convert Flare's {param} back to FastAPI's {param}
        var fastapi_tmpl = self._to_fastapi_template(tmpl)
        var method = self.router.route_method(i)
        var params = self.router.route_path_params(i)
        return Route(method=method, template=fastapi_tmpl, path_params=params)

    @staticmethod
    def _to_fastapi_template(template: String) -> String:
        """Convert Flare's OpenAPI template ({param}) to FastAPI style {param}.
        They are already the same; this is a no-op but kept for clarity."""
        return template

    # ── OpenAPI generation ───────────────────────────────────────────────────

    def openapi(self, title: String = "Milkha API", version: String = "0.1.0") raises -> String:
        """Return the OpenAPI 3.1 spec as a JSON string."""
        var spec = spec_from_router(self.router, title, version)
        return emit_openapi_json(spec)

    # ── Test client ──────────────────────────────────────────────────────────

    def test_client(self) -> FlareTestClient[Router]:
        """Create an in-process test client for this router."""
        return FlareTestClient[Router](self.router.copy())

    # ── Handler trait ────────────────────────────────────────────────────────

    def serve(self, req: Request) raises -> Response:
        """Delegate request handling to the underlying Flare Router."""
        return self.router.serve(req)
