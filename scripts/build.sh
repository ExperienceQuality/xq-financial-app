#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="${ROOT}/ios-xq-finance-app.xcodeproj"
SCHEME="${IOS_SCHEME:-ios-xq-finance-app}"
DESTINATION="${IOS_BUILD_DESTINATION:-generic/platform=iOS}"
DERIVED_DATA_PATH="${IOS_DERIVED_DATA_PATH:-${ROOT}/build/DerivedData}"
SOURCE_PACKAGES_PATH="${IOS_SOURCE_PACKAGES_PATH:-${ROOT}/build/SourcePackages}"

cd "${ROOT}"
"${ROOT}/scripts/resolve-packages.sh"
mkdir -p "${DERIVED_DATA_PATH}"

xcodebuild \
  -project "${PROJECT_PATH}" \
  -scheme "${SCHEME}" \
  -destination "${DESTINATION}" \
  -derivedDataPath "${DERIVED_DATA_PATH}" \
  -clonedSourcePackagesDirPath "${SOURCE_PACKAGES_PATH}" \
  -disableAutomaticPackageResolution \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  build
