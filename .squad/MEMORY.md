# Squad Memory

This file holds canonical, human-readable knowledge for the repository. Update it during memory maintenance when durable conventions, architecture, or decisions are discovered.

## Repository map

- `App/` — SwiftUI app (`ios-xq-finance-app`). Entry: `App/App.swift` (TabView: Finance + Fitness).
- `App/AssetModel/AssetModelViews.swift` — live portfolio (`AssetModelRootView`).
- `FinanceCore/`, `FitnessCore/` — SwiftUI-free domain packages.
- `AppTests/` / `AppUITests/` — unit + UI tests (page objects). Legacy card-deck sources/tests removed in T6 (#30).
- Epic #13 MVVM-C: characterization inventory at `docs/characterization-inventory.md`.

## Conventions

- Accessibility IDs: `FinanceAccessibility`, `FitnessAccessibility`, `SuperAppAccessibility` — frozen unless a task flags a change.
- UI-test isolation: `--xq-ui-testing` (+ reset flags). D8 hooks: `--xq-finance-bootstrap-fail`, `--xq-fitness-bootstrap-fail`, `--xq-fitness-import-fixture` (path); require `--xq-ui-testing`.

## Architecture

- Live finance is Asset Model sheets/alerts. Legacy card-deck (`ContentView` / `Portfolio*` / `PortfolioStore` / Models) **deleted** (T6 / D1 after D10).
- **D2 done:** `PersistenceSmokeTestRunner` + `scripts/verify-device-reinstall-persistence.sh` target `ProductionFinancePersistence` (DEBUG `--xq-persistence-smoke` from `XQFinanceApp.init`).
- Target MVVM-C: `@main` → `AppDependencyContainer` → `AppCoordinator` → `SuperAppRootView` (T1). Tab coordinators on app coordinator (T2/T3 via #35). `handle(AppRoute)` is internal only (no URL scheme, D4).

## Testing strategy

- Package: `./scripts/run-package-tests.sh` (`swift test` FinanceCore + FitnessCore). Wired in CI unit job (T7a).
- App unit: `./scripts/run-unit-tests.sh` (Simulator OK). Meaningful suite: `SuperAppContractTests` + T2/T3 VM tests + package tests (legacy card-deck AppTests dropped per D1/D10).
- UI evidence channel (**D9**): Simulator (`./scripts/run-ui-tests.sh`). Physical device remains local (delete-alert timing, optional smoke). Conflicts with `.cursor/rules/xcuitest-device.mdc` — rule text update is T7b.
- Dev issue closes only when paired QA has PAN Test Architect–reviewed evidence (CI URL / xcresult).

## Lessons

- `ContentUnavailableView` `actions:` can hide button accessibility identifiers from XCUITest; put Retry outside actions for CHAR-03 IDs.
- D10 honored: T2/T3 (#35) + T7a package CI landed before T6 dropped legacy AppTests.
