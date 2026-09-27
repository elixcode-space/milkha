# Contributing to Milkha

Thank you for your interest in contributing to Milkha! This document
outlines the process for setting up a development environment and the
guidelines for submitting changes.

## Development Environment

Milkha requires the [Mojo programming language](https://docs.modular.com/mojo)
and [pixi](https://pixi.sh) for dependency management.

```bash
git clone https://github.com/elixcode-space/milkha.git
cd milkha
pixi install
```

## Running Tests

Tests are written in Mojo using Flare's `TestSuite`:

```bash
pixi run test
```

## Running Linters

```bash
pixi run lint
```

## Running Benchmarks

```bash
# Mojo benchmark suite
pixi run bench

# Cross-language comparison (requires Python + uvicorn)
python3 benchmark/bench_comparison.py
```

## Submitting Changes

1. Fork the repository on GitHub
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Make your changes
4. Run tests: `pixi run test`
5. Run linter: `pixi run lint`
6. Commit with a descriptive message
7. Push to your fork
8. Submit a Pull Request

PRs should:
- Pass all existing tests
- Include tests for new features
- Follow the existing code style
- Update documentation if needed

## Code Style

- Use `mojo format` for formatting
- Keep handlers with `raises` unless they cannot fail
- Use type hints where applicable
- Keep docstrings concise and accurate

## Reporting Issues

File issues on the [GitHub issue tracker](https://github.com/elixcode-space/milkha/issues)
with:
- A clear title and description
- Steps to reproduce
- Expected behavior
- Actual behavior
- Environment info (OS, Mojo version, Flare version)
