#!/usr/bin/env bash
# Print the hardware UDID of the currently plugged-in iPhone.
# Uses `xcrun xctrace list devices` (same IDs xcodebuild -destination expects).
set -euo pipefail

list_plugged_iphone_udids() {
  # Online section only — skip "== Devices Offline ==" and simulators.
  xcrun xctrace list devices 2>/dev/null | awk '
    BEGIN { section = "" }
    /^== Devices ==$/ { section = "online"; next }
    /^== / { section = ""; next }
    section == "online" && /iPhone/ {
      if (match($0, /\(([0-9A-Fa-f]{8}-[0-9A-Fa-f]{16})\)[ \t]*$/)) {
        print substr($0, RSTART + 1, RLENGTH - 2)
      }
    }
  '
}

UDID_LIST=()
while IFS= read -r line; do
  [[ -n "${line}" ]] && UDID_LIST+=("${line}")
done < <(list_plugged_iphone_udids)

if [[ ${#UDID_LIST[@]} -eq 0 ]]; then
  echo "error: no plugged-in iPhone found via xcrun xctrace list devices" >&2
  echo "Connect, unlock, and trust the iPhone, then retry." >&2
  xcrun xctrace list devices >&2 || true
  exit 1
fi

if [[ ${#UDID_LIST[@]} -gt 1 ]]; then
  echo "error: multiple plugged-in iPhones found; leave only one connected for UI tests:" >&2
  printf '  %s\n' "${UDID_LIST[@]}" >&2
  exit 1
fi

printf '%s\n' "${UDID_LIST[0]}"
