#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SPEC_PATH="${ROOT}/project.yml"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "xcodegen is required to generate ${ROOT}/ios-xq-finance-app.xcodeproj" >&2
  exit 1
fi

cd "${ROOT}"
xcodegen generate --spec "${SPEC_PATH}"
