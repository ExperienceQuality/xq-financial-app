# iOS XQ Finance Build And Test Workflow

SwiftUI iOS app with **unit** (`AppTests`) and **UI** (`AppUITests`) layers.

## Basics

- Project: `ios-xq-finance-app.xcodeproj`
- Unit scheme: `ios-xq-finance-app` → `ios-xq-finance-appTests`
- UI scheme: `ios-xq-finance-app-ui-tests` → `ios-xq-finance-appUITests`
- App bundle ID: `com.xq.finance.ios-xq-finance-app`
- Minimum iOS deployment target: `17.0`

The UI-test target consumes the released `XQXCUITestSupport` Swift package at
version `0.1.0`. The package is intentionally linked only to
`ios-xq-finance-appUITests`; the application and unit-test targets do not
depend on it.

## Unit

```bash
./scripts/run-unit-tests.sh
```

The script resolves the committed package pins, uses deterministic build and
result directories beneath `build/`, and sets `CODE_SIGNING_ALLOWED=NO` and
`CODE_SIGNING_REQUIRED=NO`.

## Build

```bash
./scripts/build.sh
```

The build is a generic iOS build with signing disabled. Package sources are
cached under `build/SourcePackages`; dependency resolution fails if it changes
the committed `Package.resolved`.

That scheme includes `AppTests` only — not UI journeys.

## UI (Simulator)

```bash
./scripts/run-ui-tests.sh
```

Optional: `IOS_SIMULATOR_NAME='iPhone 16 Pro'` and `IOS_SIMULATOR_OS='18.5'`.

The suite uses `--xq-ui-testing` and `--xq-ui-testing-reset`. Its Application Support directory and Keychain service are distinct from normal app storage; reset removes only that UI-test namespace. XCResults land under `build/ui-test-results/`.

## Physical device

```bash
./scripts/run-device-ui-tests.sh          # UI tests → dedicated device named "IphoneTest"
./scripts/verify-device-reinstall-persistence.sh  # reinstall check → David 🥷 (iPhone Air)
./scripts/archive-ipa.sh                  # IPA export → David 🥷 (iPhone Air)
```

Requires a trusted `IphoneTest` device, `DEVELOPMENT_TEAM` (default `T99X93V7Y2`), and valid Apple Development signing. Override targets with `IOS_DEVICE_NAME` / `IOS_DEVICE_ID` (`IOS_ARCHIVE_DEVICE_NAME` for archive). Archive export needs a local `exportOptions.plist` (gitignored). Device and archive commands are local-only and are not part of the signing-free CI workflows.
