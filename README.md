# iOS XQ Finance App

Native SwiftUI finance portfolio app for iPhone/iPad.

Standard Xcode iOS app. Requires Xcode 16+, iOS 17+. Open `ios-xq-finance-app.xcodeproj` in Xcode, or build from the CLI.

## Build and unit test

```bash
./scripts/build.sh
./scripts/run-unit-tests.sh
```

Both commands resolve the committed Swift package pins, use `build/` for
derived data and results, and disable code signing. Override destinations and
paths with `IOS_BUILD_DESTINATION`, `IOS_TEST_DESTINATION`,
`IOS_DERIVED_DATA_PATH`, or `IOS_SOURCE_PACKAGES_PATH`.

## UI tests

```bash
./scripts/run-ui-tests.sh
```

See [BUILD_AND_TEST.md](BUILD_AND_TEST.md) for device scripts and signing notes.

For the dedicated physical-device UI run, use `IphoneTest` by default:

```bash
./scripts/run-device-ui-tests.sh
```

Override device selection with `IOS_DEVICE_NAME` or `IOS_DEVICE_ID`.
