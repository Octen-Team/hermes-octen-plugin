#!/usr/bin/env bash
set -euo pipefail

: "${HERMES_SOURCE:?Set HERMES_SOURCE to a Hermes Agent source checkout}"
PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec bash "$HERMES_SOURCE/scripts/run_tests.sh" "$PLUGIN_ROOT/tests" "$@"
