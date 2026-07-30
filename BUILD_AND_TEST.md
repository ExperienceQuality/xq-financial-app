# iOS XQ Finance Build And Test Workflow

SwiftUI iOS app with **unit** (`AppTests`) and **UI** (`AppUITests`) layers.

## Basics

- Project: `ios-xq-finance-app.xcodeproj`
- Unit scheme: `ios-xq-finance-app` → `ios-xq-finance-appTests`
- UI scheme: `ios-xq-finance-app-ui-tests` → `ios-xq-finance-appUITests`
- App bundle ID: `com.xq.finance.ios-xq-finance-app`
- Minimum iOS deployment target: `17.0`

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
./scripts/run-device-ui-tests.sh
./scripts/verify-device-reinstall-persistence.sh
./scripts/archive-ipa.sh
```

Requires a trusted iPhone, `DEVELOPMENT_TEAM` (default `T99X93V7Y2`), and valid Apple Development signing. Override the device with `IOS_DEVICE_ID`, or let `scripts/plugged-iphone-udid.sh` detect the plugged-in phone. Archive export needs a local `exportOptions.plist` (gitignored).
