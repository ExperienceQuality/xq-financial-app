# iOS XQ Finance App

Native SwiftUI finance portfolio app for iPhone/iPad.

Standalone Xcode project. Requires Xcode 16+, XcodeGen (optional regenerate), iOS 17+.

## Build and unit test

```bash
xcodegen generate   # optional; regenerates the Xcode project from project.yml
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
