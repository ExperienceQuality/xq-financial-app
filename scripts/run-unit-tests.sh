#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="${ROOT}/ios-xq-finance-app.xcodeproj"
SCHEME="${IOS_SCHEME:-ios-xq-finance-app}"
DESTINATION="${IOS_TEST_DESTINATION:-platform=iOS Simulator,name=iPhone 16}"
DERIVED_DATA_PATH="${IOS_DERIVED_DATA_PATH:-${ROOT}/build/DerivedData}"
SOURCE_PACKAGES_PATH="${IOS_SOURCE_PACKAGES_PATH:-${ROOT}/build/SourcePackages}"
RESULT_DIRECTORY="${ROOT}/build/unit-test-results"
RESULT_BUNDLE="${RESULT_DIRECTORY}/finance-unit-tests-$(date +%Y%m%d-%H%M%S).xcresult"

cd "${ROOT}"
"${ROOT}/scripts/resolve-packages.sh"
mkdir -p "${DERIVED_DATA_PATH}" "${RESULT_DIRECTORY}"

xcodebuild \
  -project "${PROJECT_PATH}" \
  -scheme "${SCHEME}" \
  -destination "${DESTINATION}" \
  -derivedDataPath "${DERIVED_DATA_PATH}" \
  -clonedSourcePackagesDirPath "${SOURCE_PACKAGES_PATH}" \
  -disableAutomaticPackageResolution \
  -resultBundlePath "${RESULT_BUNDLE}" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  test

echo "Unit-test result: ${RESULT_BUNDLE}"
