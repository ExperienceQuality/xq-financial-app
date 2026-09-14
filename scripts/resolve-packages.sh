#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="${ROOT}/ios-xq-finance-app.xcodeproj"
SCHEME="${IOS_SCHEME:-ios-xq-finance-app-ui-tests}"
SOURCE_PACKAGES_PATH="${IOS_SOURCE_PACKAGES_PATH:-${ROOT}/build/SourcePackages}"
PACKAGE_LOCK_PATH="${ROOT}/ios-xq-finance-app.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"

mkdir -p "${SOURCE_PACKAGES_PATH}"

xcodebuild \
  -project "${PROJECT_PATH}" \
  -scheme "${SCHEME}" \
  -clonedSourcePackagesDirPath "${SOURCE_PACKAGES_PATH}" \
  -resolvePackageDependencies

if ! git -C "${ROOT}" diff --quiet -- "${PACKAGE_LOCK_PATH}"; then
  echo "Package.resolved changed during dependency resolution; update the committed lockfile deliberately." >&2
  git -C "${ROOT}" diff -- "${PACKAGE_LOCK_PATH}" >&2
  exit 1
fi

echo "Package resolution is consistent with ${PACKAGE_LOCK_PATH}"
