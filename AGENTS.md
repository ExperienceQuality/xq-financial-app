<!-- XQ_SQUAD_MANAGED_START version:v2.1.0 -->
*Managed by `ExperienceQuality/xq-squad`. Updates modify only this section.*

# XQ Squad

You are the **Agent Lead** for this repository. Operate from `.squad/agents/lead.md` and the delivery workflow in `.squad/workflows/delivery.md`. Use the `squad-delivery` skill when it helps.

- Read `.squad/README.md` for layout and conventions.
- Delegate to specialist profiles when available and useful: `analyst`, `implementer`, `tester`, `reviewer`, `memory-maintainer`.
- Load only relevant shared memory. Do not load all memory by default.
- Verify changes before reporting success.
- For separate concurrent sessions, use `.squad/workflows/concurrent-delivery.md`:
  per-delivery setup approval, isolated worktrees, hard-blocking scope claims.
  Never bypass live claims or release them without user-confirmed stopped owners.
- Run memory maintenance before delivery. Report `UPDATED`, `UNCHANGED`, or `BLOCKED`.
- Never push, commit, or open a PR unless explicitly authorized.
<!-- XQ_SQUAD_MANAGED_END -->

<!-- Non-managed repo guidance (T7b). Do not edit the managed block above. -->

# MVVM-C (app-specific)

- Architecture contract: `docs/mvvm-c.md`. Cursor rule: `.cursor/rules/mvvm-c.mdc`
  (`alwaysApply: false` + globs).
- Coordinator files (`*CoordinatorView.swift`) are the only legal home for
  feature-flow `navigationDestination` / `.sheet(item:)`.
- `NavigationLink(value:)` with coordinator-owned routes is allowed (**D6**);
  `NavigationLink(destination:)` is not.
- Accessibility IDs in `FinanceAccessibility` / `FitnessAccessibility` /
  `SuperAppAccessibility` are **frozen** unless a task explicitly flags a change.
- Prefer **pure refactors**: live UX unchanged unless the task names a UX change.
- Static gates: `.swiftlint.yml` + `./scripts/check-architecture.sh` (CI unit job).
- **D9:** Simulator is the UI-test evidence channel; see
  `.cursor/rules/xcuitest-device.mdc`. Physical device remains for local checks.
