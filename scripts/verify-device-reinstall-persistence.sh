#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="${ROOT}/ios-xq-finance-app.xcodeproj"
SCHEME="ios-xq-finance-app"
BUNDLE_ID="com.xq.finance.ios-xq-finance-app"
export IOS_DEVICE_NAME="${IOS_DEVICE_NAME:-David 🥷}"
DEVICE_ID="${IOS_DEVICE_ID:-$("${ROOT}/scripts/plugged-iphone-udid.sh")}"
APP_PATH="${ROOT}/build/Products/Debug-iphoneos/ios-xq-finance-app.app"
SEEDED=0

log() {
  printf '==> %s\n' "$*"
}

launch_smoke() {
  local command="$1"
  xcrun devicectl device process launch \
    --device "${DEVICE_ID}" \
    --console \
    --terminate-existing \
    "${BUNDLE_ID}" \
    --xq-persistence-smoke "${command}"
}

restore_on_failure() {
  if [[ "${SEEDED}" == "1" ]]; then
    log "Restoring original portfolio after failed persistence smoke run"
    set +e
    launch_smoke restore
    set -e
  fi
}

trap restore_on_failure EXIT

cd "${ROOT}"

log "Building ${SCHEME} for physical device ${DEVICE_ID}"
xcodebuild \
  -project "${PROJECT_PATH}" \
  -scheme "${SCHEME}" \
  -destination "platform=iOS,id=${DEVICE_ID}" \
  build

log "Installing first build"
xcrun devicectl device install app --device "${DEVICE_ID}" "${APP_PATH}"

log "Seeding temporary persistence marker"
launch_smoke seed
SEEDED=1

log "Installing the same build again without uninstalling"
xcrun devicectl device install app --device "${DEVICE_ID}" "${APP_PATH}"

log "Verifying marker survived reinstall and restoring original portfolio"
launch_smoke verify
SEEDED=0

log "Device reinstall persistence verification passed"
