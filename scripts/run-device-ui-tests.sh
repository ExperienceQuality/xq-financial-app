#!/usr/bin/env bash
# Physical-device UI tests using the dedicated IphoneTest device by default.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export IOS_DEVICE_NAME="${IOS_DEVICE_NAME:-IphoneTest}"
DEVICE_ID="${IOS_DEVICE_ID:-$("${ROOT}/scripts/plugged-iphone-udid.sh")}"
TEAM_ID="${DEVELOPMENT_TEAM:-T99X93V7Y2}"
RESULT_DIRECTORY="${ROOT}/build/ui-test-results"
RESULT_BUNDLE="${RESULT_DIRECTORY}/finance-ui-tests-device-$(date +%Y%m%d-%H%M%S).xcresult"

echo "Using dedicated physical device: ${IOS_DEVICE_NAME} (${DEVICE_ID})"
echo "Using DEVELOPMENT_TEAM: ${TEAM_ID}"

mkdir -p "${RESULT_DIRECTORY}"

xcodebuild \
  -quiet \
  -project "${ROOT}/ios-xq-finance-app.xcodeproj" \
  -scheme ios-xq-finance-app-ui-tests \
  -destination "platform=iOS,id=${DEVICE_ID}" \
  "DEVELOPMENT_TEAM=${TEAM_ID}" \
  -allowProvisioningUpdates \
  -resultBundlePath "${RESULT_BUNDLE}" \
  test

echo "UI-test result: ${RESULT_BUNDLE}"
