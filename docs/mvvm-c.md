# Strict SwiftUI MVVM-C (XQ Finance)

Short in-repo contract for implementers (epic #13 / D7). Full SA/TA specs live on the
squad box; durable agent rules also live in `.cursor/rules/mvvm-c.mdc` and the
non-managed section of `AGENTS.md`.

## Target layers

| Layer | Owns | Must not |
| --- | --- | --- |
| **View** | Layout, bindings to VM/coordinator state, a11y IDs | Persistence, `store.send`, route/sheet mutation, business rules |
| **ViewModel** | Presentation state, formatting, calls into store/coordinator | Own `NavigationPath` / sheets; touch Keychain/files directly |
| **Coordinator** | `path`, `.sheet(item:)`, `navigationDestination`, feature flow chrome | Domain math; persistence I/O |
| **Store / package** | Domain + persistence protocols | `import SwiftUI`; know about app modules |

Entry: `@main` → `AppDependencyContainer` → `AppCoordinator` → `SuperAppRootView`
→ tab coordinators (`FinanceTabCoordinator`, `FitnessTabCoordinator`).

## Coordinator hierarchy

- Feature flow `navigationDestination` and `.sheet(item:)` live only in
  `*CoordinatorView.swift` (or an explicitly allowlisted coordinator container).
- `NavigationLink(value:)` with coordinator-owned route enums is allowed (**D6**).
  `NavigationLink(destination:)` is not.
- Nested `NavigationStack` inside editor/sheet chrome is allowed (toolbar host only).
- `router.path` / `sheet` mutations belong in tab coordinators, not views/VMs.
- `fullScreenCover` is reserved (ADR-7); do not invent a second cover channel without
  an epic decision.
- `TabBarAccessibilityBridge` stays in the shell (`SuperAppRootView`).

## DI

- Construct stores/coordinators in `AppDependencyContainer` (or test fakes).
- Views receive `store` + `coordinator` (or a VM that already holds them).
- No `@EnvironmentObject` / `@StateObject` / `ObservableObject` for app feature types.
  Prefer `@Observable` + `@Bindable` / `@State`.

## ViewModel rules

- `@MainActor` + `@Observable` for UI-facing VMs.
- VMs may call `store.send` / package APIs; Views must not.
- Selection/expand/collapse and form draft state are VM concerns; navigation is not.

## Module boundaries

- `FinanceCore` / `FitnessCore` Sources: no `import SwiftUI`, no app-module imports.
- App may `import FinanceCore` / `import FitnessCore`. Forbidding `import FinanceCore`
  in views is too broad (views need `FinancialAsset` etc.).
- Forbid persistence type names (`ProductionFinancePersistence`, `FileManager.default`,
  `PortfolioStore`) and `store.send` / `importSnapshot` inside `*View.swift`.

## Frozen IDs

Accessibility identifiers in `FinanceAccessibility`, `FitnessAccessibility`, and
`SuperAppAccessibility` are **frozen** unless a task explicitly flags an ID change.
Characterization and UI tests lock them (CHAR-06).

## Pure-refactor wording

MVVM-C extract work is a **pure refactor**: live Finance/Fitness UX and frozen a11y
IDs stay unchanged unless a task names a UX change. Dropping legacy card-deck unit
tests (T6) is a CI-contract change, not a live-UX change.

## Decision log pointer

Epic #13 decision IDs (D1–D10) are recorded on GitHub issues / the epic decision log.
Notable for this contract: **D6** (`NavigationLink(value:)` OK), **D7** (this doc),
**D9** (Simulator is the UI-test evidence channel; device remains local), **D10**
(T6 drops legacy tests only after T2/T3/T7a replacements are on CI).

## Enforcement

- Narrow SwiftLint custom rules: `.swiftlint.yml`
- Static architecture scan: `./scripts/check-architecture.sh`
- CI: unit job runs both after package tests (T7a)
