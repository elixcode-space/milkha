#!/usr/bin/env bash
# Type-check every Milkha source file. Mojo 1.0 has no `mojo check`, so
# `mojo build` is used as the type-checker. Binaries go to build/lint/ so the
# repository root stays clean.
set -euo pipefail
cd "$(dirname "$0")/.."

out="build/lint"
rm -rf "$out"
mkdir -p "$out"

for f in tests/*.mojo milkha/examples/*.mojo benchmark/bench_core.mojo; do
  echo "--- $f"
  mojo build -I . -o "$out/$(basename "${f%.mojo}")" "$f"
done

echo "All source files type-check."
