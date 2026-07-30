#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SIMULATOR_NAME="${IOS_SIMULATOR_NAME:-iPhone 16}"
RESULT_DIRECTORY="${ROOT}/build/ui-test-results"
RESULT_BUNDLE="${RESULT_DIRECTORY}/finance-ui-tests-$(date +%Y%m%d-%H%M%S).xcresult"

echo "Using iOS Simulator: ${SIMULATOR_NAME}"

mkdir -p "${RESULT_DIRECTORY}"

xcodebuild \
  -quiet \
  -project "${ROOT}/ios-xq-finance-app.xcodeproj" \
  -scheme ios-xq-finance-app-ui-tests \
  -destination "platform=iOS Simulator,name=${SIMULATOR_NAME}" \
  -resultBundlePath "${RESULT_BUNDLE}" \
  test

echo "UI-test result: ${RESULT_BUNDLE}"
