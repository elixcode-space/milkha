#!/usr/bin/env bash
# Run every Milkha test file. Mojo 1.0 has no `mojo test`, so each file in
# tests/ is a standalone program with an explicit `main() raises:`.
set -euo pipefail
cd "$(dirname "$0")/.."

for f in tests/*.mojo; do
  echo "--- $f"
  mojo run -I . "$f"
done

echo "All test files passed."
