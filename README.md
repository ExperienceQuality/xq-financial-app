# iOS XQ Finance App

Native SwiftUI finance portfolio app for iPhone/iPad.

Standard Xcode iOS app. Requires Xcode 16+, iOS 17+. Open `ios-xq-finance-app.xcodeproj` in Xcode, or build from the CLI.

## Build and unit test

```bash
xcodebuild \
  -project ios-xq-finance-app.xcodeproj \
  -scheme ios-xq-finance-app \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  test
```

## UI tests (Simulator)

```bash
./scripts/run-ui-tests.sh
```

See [BUILD_AND_TEST.md](BUILD_AND_TEST.md) for device scripts and signing notes.
