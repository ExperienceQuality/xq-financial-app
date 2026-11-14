#!/usr/bin/env bash
# Resolve a concrete xcodebuild -destination for an available iOS Simulator.
# Prefers IOS_SIMULATOR_NAME / IOS_SIMULATOR_OS when set; falls back to any iPhone.
set -euo pipefail

SIMULATOR_NAME="${IOS_SIMULATOR_NAME:-iPhone 16}"
SIMULATOR_OS="${IOS_SIMULATOR_OS:-}"

json_file="$(mktemp)"
trap 'rm -f "${json_file}"' EXIT

xcrun simctl list devices available -j >"${json_file}"

IOS_SIMULATOR_NAME="${SIMULATOR_NAME}" IOS_SIMULATOR_OS="${SIMULATOR_OS}" python3 - "${json_file}" <<'PY'
import json
import os
import re
import sys

path = sys.argv[1]
prefer_name = os.environ.get("IOS_SIMULATOR_NAME", "").strip()
prefer_os = os.environ.get("IOS_SIMULATOR_OS", "").strip()

with open(path, encoding="utf-8") as handle:
    payload = json.load(handle)

def runtime_version(runtime_id: str) -> tuple[int, ...]:
    match = re.search(r"iOS-(\d+)-(\d+)", runtime_id)
    if not match:
        return (0,)
    return (int(match.group(1)), int(match.group(2)))

def os_label(runtime_id: str) -> str:
    match = re.search(r"iOS-(\d+)-(\d+)", runtime_id)
    if not match:
        return "unknown"
    return f"{match.group(1)}.{match.group(2)}"

candidates = []
for runtime_id, devices in payload.get("devices", {}).items():
    if "iOS" not in runtime_id:
        continue
    version = runtime_version(runtime_id)
    label = os_label(runtime_id)
    for device in devices:
        if not device.get("isAvailable", True):
            continue
        name = device.get("name", "")
        if "iPhone" not in name:
            continue
        udid = device.get("udid")
        if not udid:
            continue
        candidates.append(
            {
                "name": name,
                "os": label,
                "version": version,
                "udid": udid,
            }
        )

if not candidates:
    print("error: no available iPhone simulators", file=sys.stderr)
    sys.exit(1)

def pick(pool):
    return max(pool, key=lambda item: (item["version"], item["name"]))

def name_matches(item):
    return not prefer_name or item["name"] == prefer_name

def os_matches(item):
    return not prefer_os or item["os"] == prefer_os

filtered = [c for c in candidates if name_matches(c) and os_matches(c)]
if not filtered and prefer_os and prefer_name:
    filtered = [c for c in candidates if name_matches(c)]
if not filtered:
    filtered = candidates

chosen = pick(filtered)
print(f"platform=iOS Simulator,id={chosen['udid']}")
print(
    f"Resolved simulator: {chosen['name']} (iOS {chosen['os']}, {chosen['udid']})",
    file=sys.stderr,
)
PY