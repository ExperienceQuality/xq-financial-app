# Squad Memory

This file holds canonical, human-readable knowledge for the repository. Update it during memory maintenance when durable conventions, architecture, or decisions are discovered.

## Repository map

- `App/` — SwiftUI app (`ios-xq-finance-app`). Entry: `App/App.swift` (TabView: Finance + Fitness).
- `App/AssetModel/AssetModelViews.swift` — live portfolio (`AssetModelRootView`).
- `FinanceCore/`, `FitnessCore/` — SwiftUI-free domain packages.
- `AppTests/` / `AppUITests/` — unit + UI tests (page objects; live suite excludes legacy Portfolio UI tests in `project.yml`).
- Epic #13 MVVM-C: characterization inventory at `docs/characterization-inventory.md`.

## Conventions

- Accessibility IDs: `FinanceAccessibility`, `FitnessAccessibility`, `SuperAppAccessibility` — frozen unless a task flags a change.
- UI-test isolation: `--xq-ui-testing` (+ reset flags). D8 hooks: `--xq-finance-bootstrap-fail`, `--xq-fitness-bootstrap-fail`, `--xq-fitness-import-fixture` (path); require `--xq-ui-testing`.

## Architecture

- Live finance is Asset Model sheets/alerts (not legacy card-deck). Legacy `ContentView` / `Portfolio*` still in tree until T6 (**D1: delete** after D10).
- **D2:** retarget `PersistenceSmokeTestRunner` + device-reinstall script at `ProductionFinancePersistence` (T6).
- Target MVVM-C: `AppDependencyContainer` + `AppCoordinator` + tab coordinators (T1+).

## Testing strategy

- Package: `./scripts/run-package-tests.sh` (`swift test` FinanceCore + FitnessCore). Wired in CI unit job (T7a).
- App unit: `./scripts/run-unit-tests.sh` (Simulator OK).
- UI evidence channel (**D9**): Simulator (`./scripts/run-ui-tests.sh`). Physical device remains local (delete-alert timing, optional smoke). Conflicts with `.cursor/rules/xcuitest-device.mdc` — rule text update is T7b.
- Dev issue closes only when paired QA has PAN Test Architect–reviewed evidence (CI URL / xcresult).

## Lessons

- `ContentUnavailableView` `actions:` can hide button accessibility identifiers from XCUITest; put Retry outside actions for CHAR-03 IDs.
- D10: keep legacy AppTests until T2/T3/T7a replacements run on CI; then T6 may drop them (D1).
