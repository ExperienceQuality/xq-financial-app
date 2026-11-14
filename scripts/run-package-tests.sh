#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

echo "==> FinanceCore package tests"
swift test --package-path FinanceCore

echo "==> FitnessCore package tests"
swift test --package-path FitnessCore

echo "Package tests passed."
