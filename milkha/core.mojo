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

    def __init__(out self, method: String, template: String, var path_params: List[String]):
        self.method = method
        self.template = template
        self.path_params = path_params^


struct APIRouter(Copyable, Defaultable, Handler, Movable):
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
    # Route counts of mounted sub-routers, so route_count() can report the
    # total number of reachable routes (Flare's Router.route_count excludes
    # mounted routes). Counts only: no Router copies are retained here.
    var _mounted_counts: List[Int]

    def __init__(out self):
        self.router = Router()
        self._mounted_counts = List[Int]()

    # ── Path-template conversion (FastAPI {param} -> Flare :param) ───────────

    @always_inline
    @staticmethod
    def _to_flare_path(path: String) -> String:
        """Convert FastAPI `{param}` to Flare `:param`.

        Optimized for the hot path (route registration time):
        - Pre-computes whether the path has params via a fast byte scan
        - The no-param case copies the input and allocates nothing else
        """
        var src = path.as_bytes()
        var n = len(src)

        # Fast path: no `{` in the path — just return a copy
        var has_param = False
        for i in range(n):
            if src[i] == 123:  # ord('{')
                has_param = True
                break

        if not has_param:
            return path.copy()

        # Slow path: convert {param} -> :param, appending codepoints
        var out = String(capacity=n)
        var i = 0
        while i < n:
            var c = src[i]
            if c == 123:  # '{'
                out += chr(Int(58))  # ':'
                i += 1
                while i < n and src[i] != 125:  # '}'
                    out += chr(Int(src[i]))
                    i += 1
                if i < n and src[i] == 125:
                    i += 1
            else:
                out += chr(Int(c))
                i += 1
        return out^

    # ── HTTP method registration (def-function overloads) ────────────────────

    @always_inline
    def get(mut self, path: String, handler: def(Request) raises thin -> Response) raises:
        self.router.get(self._to_flare_path(path), handler)

    @always_inline
    def post(mut self, path: String, handler: def(Request) raises thin -> Response) raises:
        self.router.post(self._to_flare_path(path), handler)

    @always_inline
    def put(mut self, path: String, handler: def(Request) raises thin -> Response) raises:
        self.router.put(self._to_flare_path(path), handler)

    @always_inline
    def delete(mut self, path: String, handler: def(Request) raises thin -> Response) raises:
        self.router.delete(self._to_flare_path(path), handler)

    @always_inline
    def patch(mut self, path: String, handler: def(Request) raises thin -> Response) raises:
        self.router.patch(self._to_flare_path(path), handler)

    @always_inline
    def head(mut self, path: String, handler: def(Request) raises thin -> Response) raises:
        self.router.head(self._to_flare_path(path), handler)

    @always_inline
    def options(mut self, path: String, handler: def(Request) raises thin -> Response) raises:
        self.router.options(self._to_flare_path(path), handler)

    # ── Handler-struct overloads (Extracted[H] etc.) ────────────────────────

    @always_inline
    def get[H: Handler & Copyable & Movable](
        mut self, path: String, var handler: H
    ) raises:
        self.router.get[H](self._to_flare_path(path), handler^)

    @always_inline
    def post[H: Handler & Copyable & Movable](
        mut self, path: String, var handler: H
    ) raises:
        self.router.post[H](self._to_flare_path(path), handler^)

    @always_inline
    def put[H: Handler & Copyable & Movable](
        mut self, path: String, var handler: H
    ) raises:
        self.router.put[H](self._to_flare_path(path), handler^)

    @always_inline
    def delete[H: Handler & Copyable & Movable](
        mut self, path: String, var handler: H
    ) raises:
        self.router.delete[H](self._to_flare_path(path), handler^)

    @always_inline
    def patch[H: Handler & Copyable & Movable](
        mut self, path: String, var handler: H
    ) raises:
        self.router.patch[H](self._to_flare_path(path), handler^)

    @always_inline
    def head[H: Handler & Copyable & Movable](
        mut self, path: String, var handler: H
    ) raises:
        self.router.head[H](self._to_flare_path(path), handler^)

    @always_inline
    def options[H: Handler & Copyable & Movable](
        mut self, path: String, var handler: H
    ) raises:
        self.router.options[H](self._to_flare_path(path), handler^)

    # ── Sub-router mounting ──────────────────────────────────────────────────

    @always_inline
    def include_router(mut self, prefix: String, var sub: APIRouter) raises:
        """Mount another APIRouter under a literal prefix.

        The prefix must consist of literal segments: Flare's mount only
        supports prefixes that contain no ``{param}`` or ``*`` segments, so
        a parameterized prefix is rejected here with a clear error instead
        of silently degrading to a literal one.
        """
        var src = prefix.as_bytes()
        for i in range(len(src)):
            var c = src[i]
            if c == 123 or c == 42:  # '{' or '*'
                raise Error(
                    "include_router prefix must be literal (no {param} or *): " + prefix
                )
        self.router.mount(prefix.copy(), sub.router.copy())
        var nested = 0
        for i in range(len(sub._mounted_counts)):
            nested += sub._mounted_counts[i]
        self._mounted_counts.append(nested + sub.router.route_count())

    # ── Low-level route registration ────────────────────────────────────────

    @always_inline
    def add_api_route(
        mut self,
        path: String,
        handler: def(Request) raises thin -> Response,
        methods: List[String],
    ) raises:
        """Register a handler for an arbitrary set of HTTP methods.

        Mirrors FastAPI's ``router.add_api_route``.

        Optimized: converts path once, then dispatches methods via
        direct byte comparison to avoid String allocation overhead.
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

    @always_inline
    def route_count(self) -> Int:
        """Total routes reachable through this router, including mounts."""
        var total = self.router.route_count()
        for i in range(len(self._mounted_counts)):
            total += self._mounted_counts[i]
        return total

    @always_inline
    def route(self, i: Int) -> Route:
        """Return route metadata for the i-th registered route."""
        var tmpl = self.router.route_openapi_template(i)
        # Convert Flare's {param} back to FastAPI's {param}
        var fastapi_tmpl = self._to_fastapi_template(tmpl)
        var method = self.router.route_method(i)
        var params = self.router.route_path_params(i)
        return Route(method^, fastapi_tmpl^, params^)

    @staticmethod
    def _to_fastapi_template(template: String) -> String:
        """Convert Flare's OpenAPI template ({param}) to FastAPI style {param}.
        They are already the same; this is a no-op but kept for clarity."""
        return template

    # ── OpenAPI generation ───────────────────────────────────────────────────

    def openapi(self, title: String = "Milkha API", version: String = "0.1.1") raises -> String:
        """Return the OpenAPI 3.1 spec as a JSON string."""
        var spec = spec_from_router(self.router, title, version)
        return emit_openapi_json(spec)

    # ── Test client ──────────────────────────────────────────────────────────

    def test_client(self) -> FlareTestClient[Router]:
        """Create an in-process test client for this router."""
        return FlareTestClient[Router](self.router.copy())

    # ── Handler trait ────────────────────────────────────────────────────────

    def serve(self, req: Request) raises -> Response:
        """Delegate request handling to the underlying Flare Router.

        Direct delegate with no intermediate allocation or branching.
        The Flare Router handles all routing internally.
        """
        return self.router.serve(req)
