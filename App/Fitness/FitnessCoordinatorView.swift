import FitnessCore
import SwiftUI
import UniformTypeIdentifiers

struct FitnessCoordinatorView: View {
    let store: FitnessStore
    @Bindable var coordinator: FitnessTabCoordinator
    @State private var importViewModel: FitnessImportViewModel
    @State private var didApplyImportFixture = false

    init(store: FitnessStore, coordinator: FitnessTabCoordinator) {
        self.store = store
        self.coordinator = coordinator
        _importViewModel = State(
            initialValue: FitnessImportViewModel(store: store, coordinator: coordinator)
        )
    }

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            RoutineListView(
                viewModel: RoutineListViewModel(store: store, coordinator: coordinator)
            )
            .navigationDestination(for: FitnessRoute.self) { route in
                switch route {
                case .routine(let routineID):
                    RoutineWorkspaceView(
                        viewModel: RoutineWorkspaceViewModel(
                            store: store,
                            coordinator: coordinator,
                            routineID: routineID
                        )
                    )
                case let .trainingDay(routineID, dayID):
                    TrainingDayView(
                        viewModel: TrainingDayViewModel(
                            store: store,
                            coordinator: coordinator,
                            routineID: routineID,
                            dayID: dayID
                        )
                    )
                case .snapshotReport(let routineID):
                    SnapshotReportView(
                        viewModel: SnapshotReportViewModel(store: store, routineID: routineID)
                    )
                }
            }
        }
        .sheet(item: $coordinator.sheet) { destination in
            switch destination {
            case .createRoutine:
                RoutineEditorView(
                    model: RoutineEditorModel(store: store),
                    onSaved: { coordinator.dismissSheet() }
                )
            case let .trainingSession(routineID, sessionID):
                TrainingSessionEditorView(
                    model: TrainingSessionEditorModel(
                        store: store,
                        routineID: routineID,
                        sessionID: sessionID
                    ),
                    onSaved: { coordinator.dismissSheet() }
                )
            case let .exercise(routineID, dayID, exerciseID):
                ExerciseEditorView(
                    model: ExerciseEditorModel(
                        store: store,
                        routineID: routineID,
                        dayID: dayID,
                        exerciseID: exerciseID
                    ),
                    onSaved: { coordinator.dismissSheet() }
                )
            }
        }
        .fileImporter(
            isPresented: $coordinator.isImporting,
            allowedContentTypes: [.json],
            onCompletion: importViewModel.handleImport
        )
        .safeAreaInset(edge: .bottom) {
            if let importStatus = coordinator.importStatus {
                Text(importStatus.message)
                    .font(.footnote)
                    .foregroundStyle(importStatus.isError ? XQPalette.destructive : XQPalette.ink)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(XQPalette.softFill)
                    .accessibilityIdentifier(SuperAppAccessibility.fitnessImportStatus)
            }
        }
        .onAppear(perform: applyUITestImportFixtureIfRequested)
    }

    private func applyUITestImportFixtureIfRequested() {
        guard !didApplyImportFixture,
              let fixtureURL = FitnessImportTestHook.fixtureURL(
                arguments: CommandLine.arguments
              ) else {
            return
        }
        didApplyImportFixture = true
        importViewModel.handleImport(.success(fixtureURL))
    }
}
