#!/usr/bin/env bash
# Static MVVM-C architecture gate (T7b / SA §4.2 / TA §4).
# Prefer this script over in-process AppTests so CI does not need the app runtime.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

SCAN_ROOT="${ARCHITECTURE_SCAN_ROOT:-App}"
PACKAGE_ROOTS=(FinanceCore/Sources FitnessCore/Sources)
FIXTURE_MODE=0
FAILURES=0
REPORT=()

log() { printf '%s\n' "$*"; }
fail() {
  FAILURES=$((FAILURES + 1))
  REPORT+=("FAIL: $*")
  log "FAIL: $*"
}
pass() {
  REPORT+=("PASS: $*")
  log "PASS: $*"
}

usage() {
  cat <<'EOF'
Usage: ./scripts/check-architecture.sh [--fixtures]

  Default: scan App/ + package Sources with allowlists.
  --fixtures: scan scripts/architecture-fixtures/ should-fail + positive controls.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ "${1:-}" == "--fixtures" ]]; then
  FIXTURE_MODE=1
  SCAN_ROOT="scripts/architecture-fixtures"
fi

# Paths ignored entirely (legacy until T6; previews; fixtures when not in fixture mode).
is_excluded_path() {
  local path="$1"
  case "${path}" in
    App/Views/*|App/ViewModels/*|App/Models/*|App/Services/*)
      [[ "${FIXTURE_MODE}" == "0" ]] && return 0
      ;;
    scripts/architecture-fixtures/*)
      [[ "${FIXTURE_MODE}" == "0" ]] && return 0
      ;;
  esac
  return 1
}

# Coordinator containers may host navigationDestination / sheet(item:).
is_coordinator_container() {
  local path="$1"
  local base
  base="$(basename "${path}")"
  case "${base}" in
    *CoordinatorView.swift) return 0 ;;
  esac
  return 1
}

# Tab coordinators may mutate path / sheet.
is_tab_coordinator() {
  local path="$1"
  local base
  base="$(basename "${path}")"
  case "${base}" in
    FitnessTabCoordinator.swift|FinanceTabCoordinator.swift) return 0 ;;
  esac
  return 1
}

is_view_file() {
  local base
  base="$(basename "$1")"
  [[ "${base}" == *View.swift ]]
}

# Strip block comments / #Preview bodies roughly for false-positive reduction.
strip_ignored_regions() {
  local file="$1"
  # Drop #Preview { ... } blocks (non-greedy via awk brace depth after #Preview).
  awk '
    BEGIN { skip=0; depth=0 }
    {
      line=$0
      if (skip==0 && line ~ /#Preview([[:space:]]|\(|$)/) {
        skip=1
        depth=0
      }
      if (skip==1) {
        for (i=1; i<=length(line); i++) {
          c=substr(line,i,1)
          if (c=="{") depth++
          else if (c=="}") {
            depth--
            if (depth<=0) { skip=0; next }
          }
        }
        next
      }
      print line
    }
  ' "${file}"
}

scan_file_app() {
  local file="$1"
  local content
  content="$(strip_ignored_regions "${file}")"

  if is_view_file "${file}"; then
    if printf '%s\n' "${content}" | grep -nE 'store\.send[[:space:]]*\(' >/dev/null; then
      fail "${file}: store.send in View"
    fi
    if printf '%s\n' "${content}" | grep -nE 'importSnapshot[[:space:]]*\(' >/dev/null; then
      fail "${file}: importSnapshot in View"
    fi
    if printf '%s\n' "${content}" | grep -nE 'PortfolioStore\.' >/dev/null; then
      fail "${file}: PortfolioStore. in View"
    fi
    if printf '%s\n' "${content}" | grep -nE 'ProductionFinancePersistence|FileManager\.default' >/dev/null; then
      fail "${file}: persistence type in View"
    fi
    if printf '%s\n' "${content}" | grep -nE '@EnvironmentObject' >/dev/null; then
      fail "${file}: @EnvironmentObject in View"
    fi
  fi

  if printf '%s\n' "${content}" | grep -nE 'NavigationLink[[:space:]]*\([[:space:]]*destination[[:space:]]*:' >/dev/null; then
    fail "${file}: NavigationLink(destination:) banned (use value: / D6)"
  fi

  if printf '%s\n' "${content}" | grep -nE '\.navigationDestination[[:space:]]*\(' >/dev/null; then
    if ! is_coordinator_container "${file}"; then
      fail "${file}: navigationDestination outside coordinator container"
    fi
  fi

  if printf '%s\n' "${content}" | grep -nE '\.sheet[[:space:]]*\([[:space:]]*item[[:space:]]*:' >/dev/null; then
    if ! is_coordinator_container "${file}"; then
      fail "${file}: .sheet(item:) outside coordinator container"
    fi
  fi

  if printf '%s\n' "${content}" | grep -nE '\bObservableObject\b|@StateObject|@EnvironmentObject' >/dev/null; then
    # Allow UIKit representables / system types; flag app-feature store patterns.
    if printf '%s\n' "${content}" | grep -nE '@EnvironmentObject[[:space:]]+var[[:space:]].*(Store|Coordinator|ViewModel)|@StateObject[[:space:]]+var[[:space:]].*(Store|Coordinator|ViewModel)|:\s*ObservableObject' >/dev/null; then
      fail "${file}: ObservableObject/@StateObject/@EnvironmentObject for app feature types"
    fi
  fi

  # path / sheet mutations (heuristic): coordinator.path= or .path.append / sheet =
  if printf '%s\n' "${content}" | grep -nE '(coordinator|router)\.path\.(append|remove|removeAll)|\.path[[:space:]]*=' >/dev/null; then
    if ! is_tab_coordinator "${file}"; then
      fail "${file}: path mutation outside tab coordinator"
    fi
  fi
  if printf '%s\n' "${content}" | grep -nE '(coordinator|router)\.sheet[[:space:]]*=' >/dev/null; then
    if ! is_tab_coordinator "${file}"; then
      fail "${file}: sheet mutation outside tab coordinator"
    fi
  fi
}

scan_package_file() {
  local file="$1"
  if grep -nE '^import[[:space:]]+SwiftUI[[:space:]]*$' "${file}" >/dev/null; then
    fail "${file}: package Sources must not import SwiftUI"
  fi
  if grep -nE '^import[[:space:]]+ios_xq_finance_app[[:space:]]*$' "${file}" >/dev/null; then
    fail "${file}: package Sources must not import app module"
  fi
}

scan_tree() {
  local root="$1"
  local mode="$2"
  [[ -d "${root}" ]] || return 0
  while IFS= read -r -d '' file; do
    if is_excluded_path "${file}"; then
      continue
    fi
    case "${mode}" in
      app) scan_file_app "${file}" ;;
      package) scan_package_file "${file}" ;;
    esac
  done < <(find "${root}" -type f -name '*.swift' -print0)
}

# After T6, legacy types must not remain under App/. Soft check: warn via fail only
# when files exist and we are not excluding them (post-T6). With excludes active,
# skip ContentView presence check.
check_legacy_absent_when_unexcluded() {
  if [[ "${FIXTURE_MODE}" == "1" ]]; then
    return 0
  fi
  # If legacy exclude dirs are gone / empty of ContentView, assert absence.
  if [[ ! -d App/Views ]] && [[ ! -d App/ViewModels ]]; then
    if [[ -f App/Views/ContentView.swift ]] || [[ -f App/ViewModels/PortfolioViewModel.swift ]]; then
      fail "ContentView / PortfolioViewModel still present after legacy tree removal"
    else
      pass "legacy ContentView / PortfolioViewModel absent (post-T6)"
    fi
  else
    pass "legacy App/Views|ViewModels|Models|Services excluded until T6"
  fi
}

run_default_scan() {
  log "==> Architecture scan (App + packages)"
  scan_tree "${SCAN_ROOT}" app
  for pkg in "${PACKAGE_ROOTS[@]}"; do
    scan_tree "${pkg}" package
  done
  check_legacy_absent_when_unexcluded
}

run_fixture_scan() {
  log "==> Architecture fixture scan (expect failures in should-fail/)"
  local should_fail_root="${SCAN_ROOT}/should-fail"
  local should_pass_root="${SCAN_ROOT}/should-pass"
  local before=${FAILURES}

  if [[ -d "${should_fail_root}" ]]; then
    local prior=${FAILURES}
    scan_tree "${should_fail_root}" app
    # Also scan package-like fixture if present
    if [[ -d "${should_fail_root}/package" ]]; then
      scan_tree "${should_fail_root}/package" package
    fi
    local delta=$((FAILURES - prior))
    if [[ "${delta}" -lt 1 ]]; then
      fail "should-fail fixtures produced no violations (expected >=1)"
    else
      pass "should-fail fixtures produced ${delta} violation(s)"
      # Reset failure count for should-fail expected hits — they prove the scanner works.
      FAILURES=${prior}
    fi
  else
    fail "missing ${should_fail_root}"
  fi

  if [[ -d "${should_pass_root}" ]]; then
    local prior_pass=${FAILURES}
    scan_tree "${should_pass_root}" app
    local delta_pass=$((FAILURES - prior_pass))
    if [[ "${delta_pass}" -gt 0 ]]; then
      fail "should-pass fixtures unexpectedly failed (${delta_pass})"
    else
      pass "should-pass fixtures clean"
    fi
  else
    fail "missing ${should_pass_root}"
  fi

  # Fixture mode success means: should-fail tripped, should-pass clean, and we
  # discarded expected should-fail counts above.
  :
}

if [[ "${FIXTURE_MODE}" == "1" ]]; then
  run_fixture_scan
else
  run_default_scan
fi

log "==> Summary"
for line in "${REPORT[@]+"${REPORT[@]}"}"; do
  log "${line}"
done

if [[ "${FAILURES}" -gt 0 ]]; then
  log "Architecture check failed with ${FAILURES} issue(s)."
  exit 1
fi

log "Architecture check passed."
exit 0
