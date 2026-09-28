#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SIMULATOR_NAME="${IOS_SIMULATOR_NAME:-iPhone 16}"
SIMULATOR_OS="${IOS_SIMULATOR_OS:-}"
DERIVED_DATA_PATH="${IOS_DERIVED_DATA_PATH:-${ROOT}/build/DerivedData}"
SOURCE_PACKAGES_PATH="${IOS_SOURCE_PACKAGES_PATH:-${ROOT}/build/SourcePackages}"
RESULT_DIRECTORY="${ROOT}/build/ui-test-results"
RESULT_BUNDLE="${RESULT_DIRECTORY}/finance-ui-tests-$(date +%Y%m%d-%H%M%S).xcresult"

echo "Using iOS Simulator: ${SIMULATOR_NAME}"

cd "${ROOT}"
"${ROOT}/scripts/generate-project.sh"
"${ROOT}/scripts/resolve-packages.sh"
mkdir -p "${DERIVED_DATA_PATH}" "${RESULT_DIRECTORY}"

DESTINATION="platform=iOS Simulator,name=${SIMULATOR_NAME}"
if [[ -n "${SIMULATOR_OS}" ]]; then
  DESTINATION+=",OS=${SIMULATOR_OS}"
fi

xcodebuild \
  -quiet \
  -project "${ROOT}/ios-xq-finance-app.xcodeproj" \
  -scheme ios-xq-finance-app-ui-tests \
  -destination "${DESTINATION}" \
  -derivedDataPath "${DERIVED_DATA_PATH}" \
  -clonedSourcePackagesDirPath "${SOURCE_PACKAGES_PATH}" \
  -disableAutomaticPackageResolution \
  -resultBundlePath "${RESULT_BUNDLE}" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  test

echo "UI-test result: ${RESULT_BUNDLE}"
