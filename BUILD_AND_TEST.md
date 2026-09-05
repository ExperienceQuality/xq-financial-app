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
xcodebuild \
  -project ios-xq-finance-app.xcodeproj \
  -scheme ios-xq-finance-app \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  test
```

That scheme includes `AppTests` only — not UI journeys.

## UI (Simulator)

```bash
./scripts/run-ui-tests.sh
```

Optional: `IOS_SIMULATOR_NAME='iPhone 16 Pro'`.

The suite uses `--xq-ui-testing` and `--xq-ui-testing-reset`. Its Application Support directory and Keychain service are distinct from normal app storage; reset removes only that UI-test namespace. XCResults land under `build/ui-test-results/`.

## Physical device (optional)

```bash
./scripts/run-device-ui-tests.sh          # UI tests → device named "iPhone" (iPhone 12)
./scripts/verify-device-reinstall-persistence.sh  # reinstall check → David 🥷 (iPhone Air)
./scripts/archive-ipa.sh                  # IPA export → David 🥷 (iPhone Air)
```

Requires trusted iPhones, `DEVELOPMENT_TEAM` (default `T99X93V7Y2`), and valid Apple Development signing. Override targets with `IOS_DEVICE_NAME` / `IOS_DEVICE_ID` (`IOS_ARCHIVE_DEVICE_NAME` for archive). Archive export needs a local `exportOptions.plist` (gitignored).
