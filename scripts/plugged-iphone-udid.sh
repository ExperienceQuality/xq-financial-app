#!/usr/bin/env bash
# Print the hardware UDID of a plugged-in physical iPhone.
# Prefers devicectl (model-aware); falls back to xctrace list devices.
set -euo pipefail

list_plugged_iphones_devicectl() {
  local json_file
  json_file="$(mktemp)"
  trap "rm -f '${json_file}'" RETURN

  if ! xcrun devicectl list devices --json-output "$json_file" --quiet 2>/dev/null; then
    return 1
  fi

  IOS_DEVICE_NAME="${IOS_DEVICE_NAME:-}" python3 - "$json_file" <<'PY'
import json
import os
import sys

path = sys.argv[1]
name_filter = os.environ.get("IOS_DEVICE_NAME", "").strip().lower()

with open(path, encoding="utf-8") as handle:
    payload = json.load(handle)

matches = []
for device in payload.get("result", {}).get("devices", []):
    hardware = device.get("hardwareProperties", {})
    if hardware.get("deviceType") != "iPhone":
        continue

    connection = device.get("connectionProperties", {})
    if connection.get("transportType") != "wired":
        continue
    if connection.get("tunnelState") != "connected":
        continue

    props = device.get("deviceProperties", {})
    udid = hardware.get("udid")
    if not udid:
        continue

    display_name = props.get("name") or "iPhone"
    model = hardware.get("marketingName") or hardware.get("productType") or "iPhone"
    matches.append((display_name, model, udid))

if name_filter:
    by_name = [
        match
        for match in matches
        if name_filter in match[0].lower()
    ]
    if by_name:
        matches = by_name
    else:
        by_model = [
            match
            for match in matches
            if name_filter in match[1].lower()
        ]
        if by_model:
            matches = by_model

for display_name, model, udid in matches:
    print(f"{display_name}\t{model}\t{udid}")
PY
}

list_plugged_iphones_xctrace() {
  # Online iOS devices with a version tuple before the hardware UDID.
  xcrun xctrace list devices 2>/dev/null | awk '
    BEGIN { section = "" }
    /^== Devices ==$/ { section = "online"; next }
    /^== / { section = ""; next }
    section == "online" && /\([0-9]+\.[0-9]+(\.[0-9]+)?\)/ && !/Watch|iPad|Apple TV|Apple Vision|HomePod/ {
      if (match($0, /\(([0-9A-Fa-f]{8}-[0-9A-Fa-f]{16})\)[ \t]*$/)) {
        udid = substr($0, RSTART + 1, RLENGTH - 2)
        name = $0
        sub(/ \([0-9]+\.[0-9]+(\.[0-9]+)?\) \([0-9A-Fa-f-]+\)[ \t]*$/, "", name)
        print name "\tiPhone\t" udid
      }
    }
  '
}

collect_matches() {
  local line name model udid
  DEVICE_ROWS=()

  if list_plugged_iphones_devicectl >"${TMP_LIST}" 2>/dev/null; then
    :
  elif list_plugged_iphones_xctrace >"${TMP_LIST}" 2>/dev/null; then
    :
  else
    : >"${TMP_LIST}"
  fi

  while IFS= read -r line || [[ -n "${line}" ]]; do
    [[ -n "${line}" ]] || continue
    IFS=$'\t' read -r name model udid <<<"${line}"
    DEVICE_ROWS+=("${name}|${model}|${udid}")
  done <"${TMP_LIST}"
}

apply_name_filter() {
  local row name model udid filter="${IOS_DEVICE_NAME:-}"
  local -a filtered=()
  local filter_lc name_lc model_lc

  [[ -n "${filter}" ]] || return 0
  filter_lc="$(printf '%s' "${filter}" | tr '[:upper:]' '[:lower:]')"

  for row in "${DEVICE_ROWS[@]}"; do
    IFS='|' read -r name model udid <<<"${row}"
    name_lc="$(printf '%s' "${name}" | tr '[:upper:]' '[:lower:]')"
    if [[ "${name_lc}" == *"${filter_lc}"* ]]; then
      filtered+=("${row}")
    fi
  done

  if [[ ${#filtered[@]} -eq 0 ]]; then
    for row in "${DEVICE_ROWS[@]}"; do
      IFS='|' read -r name model udid <<<"${row}"
      model_lc="$(printf '%s' "${model}" | tr '[:upper:]' '[:lower:]')"
      if [[ "${model_lc}" == *"${filter_lc}"* ]]; then
        filtered+=("${row}")
      fi
    done
  fi

  if [[ ${#filtered[@]} -gt 0 ]]; then
    DEVICE_ROWS=("${filtered[@]}")
  fi
}

TMP_LIST="$(mktemp)"
trap 'rm -f "${TMP_LIST}"' EXIT

DEVICE_ROWS=()
collect_matches
apply_name_filter

if [[ ${#DEVICE_ROWS[@]} -eq 0 ]]; then
  echo "error: no plugged-in iPhone found" >&2
  echo "Connect, unlock, and trust the iPhone, then retry." >&2
  if [[ -n "${IOS_DEVICE_NAME:-}" ]]; then
    echo "No device matched IOS_DEVICE_NAME=${IOS_DEVICE_NAME}" >&2
  fi
  xcrun devicectl list devices >&2 || xcrun xctrace list devices >&2 || true
  exit 1
fi

if [[ ${#DEVICE_ROWS[@]} -gt 1 ]]; then
  echo "error: multiple plugged-in iPhones found; unplug extras or set IOS_DEVICE_NAME / IOS_DEVICE_ID:" >&2
  for row in "${DEVICE_ROWS[@]}"; do
    IFS='|' read -r name model udid <<<"${row}"
    printf '  %s (%s) %s\n' "${name}" "${model}" "${udid}" >&2
  done
  exit 1
fi

IFS='|' read -r _ _ udid <<<"${DEVICE_ROWS[0]}"
printf '%s\n' "${udid}"
