# Characterization inventory (T0 / epic #13)

Baseline for live Finance + Fitness path at `main` @ W0. Frozen a11y IDs in
`FinanceAccessibility`, `FitnessAccessibility`, `SuperAppAccessibility`.

**D9 flag:** Simulator is the UI-test evidence channel (approved). This conflicts
with `.cursor/rules/xcuitest-device.mdc` (alwaysApply: device-only). Exact rule
text deferred to T7b; physical-device runs remain local (delete-alert timing,
optional smoke).

**D8 hooks:** `--xq-finance-bootstrap-fail`, `--xq-fitness-bootstrap-fail`,
`--xq-fitness-import-fixture` (+ path), only with `--xq-ui-testing`. No
production launch sets these.

## Flow inventory

| Flow | Covering test | Notes |
| --- | --- | --- |
| Default Finance tab + stable tab IDs | `SuperAppShellTests.testFinanceIsDefaultAndBothFeatureTabsHaveStableIdentifiers` | |
| Tab switch retains finance asset + fitness routine **data** | `SuperAppShellTests.testFeatureSwitchingRetainsFinanceAssetAndFitnessRoutineState` | Data only |
| Nav stack retained across tabs (CHAR-10) | `CharacterizationUITests.testFitnessPushedScreenSurvivesFinanceTabRoundTrip` | P0 |
| Finance empty + add asset | `AssetModelE2ETests.testEmptyPortfolioShowsVNDHeaderAndAddAssetAction` | |
| Create USD/VND assets | `AssetModelE2ETests.testCreateUSDAndVNDAssetsStartsAtZeroAndCardsUseNativeCurrency` | |
| Price edit | `AssetModelE2ETests.testPriceEditUpdatesNativeCardAndPortfolioSummary` | |
| Exchange rate recalc | `AssetModelE2ETests.testExchangeRateChangeRecalculatesUSDContributionButNotVNDAsset` | |
| Add/subtract units | `AssetModelE2ETests.testAddAndSubtractUnitsCreateTransactionsAndRecalculateSummary` | |
| Overdraft rejected | `AssetModelE2ETests.testSubtractingMoreThanAvailableIsRejectedWithoutMutation` | |
| Delete cancel / confirm | `AssetModelE2ETests.testDeleteCancelPreservesAssetAndConfirmRemovesOnlySelectedAsset`, `AssetDeletionTests` | No new CHAR |
| Expand/collapse card | `AssetModelE2ETests.testTappingExpandedAssetCardCollapsesActionsAndDetails` | |
| Live asset validation / cancel (CHAR-07) | `CharacterizationUITests.testBlankAssetFieldsAndInvalidEditorsDoNotMutate` | P1 |
| Fractional display / comma (CHAR-05 UI) | `CharacterizationUITests.testFractionalUSDDisplayAndCommaDecimalPrice` | P0 display |
| Finance/Fitness bootstrap failure + Retry (CHAR-03) | `CharacterizationUITests.testFinanceBootstrapFailureShowsRetryWhileFitnessLoads` (+ fitness twin) | D8 |
| Fitness import success / malformed (CHAR-02) | `CharacterizationUITests.testFitnessImportFixtureCreatesRoutineAndMalformedShowsError` | D8 |
| Routine create + relaunch | `RoutineLifecycleTests.testRoutineCreationNavigationAndRelaunchPersistence` | |
| Sessions add/rename/delete + relaunch | `RoutineLifecycleTests.testTrainingSessionsCanBeAddedRenamedDeletedAndPersisted` | |
| Exercise relaunch (CHAR-04) | `CharacterizationUITests.testExerciseSurvivesRelaunchAndResetClearsIt` | P1 |
| Snapshot Progress push + Latest Comparison (CHAR-09) | `CharacterizationUITests.testSnapshotProgressIsPushAndLatestComparisonDoesNotAddSnapshot` | P0 |
| Multi-snapshot progress labels | `SevenDaySnapshotTests.testSessionExerciseDrillDownAndThreeSnapshotComparisonPersists` | |
| Routine / exercise editor validation | `RoutineEditorValidationTests`, `ExerciseEditorValidationTests` | |
| Financial accuracy unit (CHAR-05) | `FinanceStoreTests.testCharacterizationFinancialAccuracyBoundaries` (+ existing store tests) | |
| A11y ID freeze (CHAR-06) | `CharacterizationContractTests.testFinanceFitnessAndSuperAppAccessibilityIdentifiersAreUniqueAndStable` | |
| ProductionFinancePersistence (CHAR-08) | `ProductionFinancePersistenceTests` | |
| FitnessRouter bag | `CharacterizationContractTests.testFitnessRouterPathAndSheetAreObservable` | Optional |
| Package suites on CI (CHAR-01) | T7a / `scripts/run-package-tests.sh` | Not this issue |

## P0 / P1 status

| CHAR | Priority | Status |
| --- | --- | --- |
| CHAR-02 import UI | P0 | Test + D8 hook |
| CHAR-03 bootstrap Retry | P0 | Test + D8 hook |
| CHAR-05 financial accuracy | P0 | Unit + UI display |
| CHAR-06 frozen a11y IDs | P0 | Unit |
| CHAR-09 snapshot push | P0 | UI |
| CHAR-10 stack across tabs | P0 | UI |
| CHAR-04 exercise relaunch | P1 | UI |
| CHAR-07 live validation | P1 | UI |
| CHAR-08 ProductionFinancePersistence | P1 | Unit |
