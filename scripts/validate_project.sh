#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: scripts/validate_project.sh /path/to/h5/app" >&2
  exit 2
fi

PROJECT_ROOT="$1"
if [[ ! -d "$PROJECT_ROOT" ]]; then
  echo "FAIL project root does not exist: $PROJECT_ROOT" >&2
  exit 1
fi

if [[ ! -f "$PROJECT_ROOT/package.json" ]]; then
  echo "FAIL not a H5/Web app: missing package.json" >&2
  exit 1
fi

if [[ ! -d "$PROJECT_ROOT/src" && ! -d "$PROJECT_ROOT/app" && ! -d "$PROJECT_ROOT/pages" && ! -f "$PROJECT_ROOT/index.html" ]]; then
  echo "FAIL not a H5/Web app: missing src/, app/, pages/ or index.html" >&2
  exit 1
fi

python3 "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/scripts/project_snapshot.py" "$PROJECT_ROOT" >/dev/null
echo "PASS project is valid for H5 Forge: $PROJECT_ROOT"
