#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="${ROOT}/ios-xq-finance-app.xcodeproj"
SCHEME="${IOS_SCHEME:-ios-xq-finance-app}"
CONFIGURATION="${IOS_CONFIGURATION:-Release}"
ARCHIVE_PATH="${IOS_ARCHIVE_PATH:-${ROOT}/build/ios-xq-finance-app.xcarchive}"
EXPORT_PATH="${IOS_EXPORT_PATH:-${ROOT}/build/ipa}"
EXPORT_OPTIONS_PLIST="${IOS_EXPORT_OPTIONS_PLIST:-${ROOT}/exportOptions.plist}"
export IOS_DEVICE_NAME="${IOS_ARCHIVE_DEVICE_NAME:-David 🥷}"
DEVICE_ID="${IOS_DEVICE_ID:-$("${ROOT}/scripts/plugged-iphone-udid.sh")}"

log() {
  printf '==> %s\n' "$*" >&2
}

verify_device_provisioning() {
  local ipa_path="$1"
  local device_id="$2"
  local profile_path
  local plist_path

  profile_path="$(mktemp)"
  plist_path="$(mktemp)"
  trap 'rm -f "${profile_path}" "${plist_path}"' RETURN

  unzip -p "${ipa_path}" 'Payload/*.app/embedded.mobileprovision' >"${profile_path}"
  security cms -D -i "${profile_path}" >"${plist_path}"

  if ! /usr/libexec/PlistBuddy -c 'Print :ProvisionedDevices' "${plist_path}" >/dev/null 2>&1; then
    printf 'Provisioning profile in %s does not list provisioned devices\n' "${ipa_path}" >&2
    exit 1
  fi

  if ! /usr/libexec/PlistBuddy -c 'Print :ProvisionedDevices' "${plist_path}" | grep -Fq "${device_id}"; then
    printf 'Provisioning profile in %s does not include device %s\n' "${ipa_path}" "${device_id}" >&2
    exit 1
  fi

  log "Provisioning profile includes device ${device_id}"
}

cd "${ROOT}"
mkdir -p "$(dirname "${ARCHIVE_PATH}")" "${EXPORT_PATH}"

log "Archiving ${SCHEME} (${CONFIGURATION}) for device ${DEVICE_ID}"
xcodebuild \
  -project "${PROJECT_PATH}" \
  -scheme "${SCHEME}" \
  -destination "generic/platform=iOS" \
  -configuration "${CONFIGURATION}" \
  -archivePath "${ARCHIVE_PATH}" \
  -allowProvisioningUpdates \
  archive \
  1>&2

log "Exporting IPA"
xcodebuild \
  -exportArchive \
  -archivePath "${ARCHIVE_PATH}" \
  -exportPath "${EXPORT_PATH}" \
  -exportOptionsPlist "${EXPORT_OPTIONS_PLIST}" \
  -allowProvisioningUpdates \
  1>&2

ipa_path="${EXPORT_PATH}/${SCHEME}.ipa"
if [[ ! -f "${ipa_path}" ]]; then
  ipa_candidates=("${EXPORT_PATH}"/*.ipa)
  if [[ -e "${ipa_candidates[0]}" ]]; then
    ipa_path="${ipa_candidates[0]}"
  else
    printf 'No IPA was exported under %s\n' "${EXPORT_PATH}" >&2
    exit 1
  fi
fi

verify_device_provisioning "${ipa_path}" "${DEVICE_ID}"

cd "$(dirname "${ipa_path}")"
printf '%s/%s\n' "$PWD" "$(basename "${ipa_path}")"
