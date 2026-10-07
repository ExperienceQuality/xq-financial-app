import FitnessCore
import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct FitnessRootView: View {
    let store: FitnessStore
    @State private var router = FitnessRouter()
    @State private var isImporting = false
    @State private var importStatus: FitnessImportStatus?

    var body: some View {
        @Bindable var router = router

        NavigationStack(path: $router.path) {
            RoutineListView(
                store: store,
                router: router,
                onImport: { isImporting = true }
            )
                .navigationDestination(for: FitnessRoute.self) { route in
                    switch route {
                    case .routine(let routineID):
                        RoutineWorkspaceView(store: store, router: router, routineID: routineID)
                    case let .trainingDay(routineID, dayID):
                        TrainingDayView(
                            store: store,
                            router: router,
                            routineID: routineID,
                            dayID: dayID
                        )
                    case .snapshotReport(let routineID):
                        SnapshotReportView(store: store, routineID: routineID)
                    }
                }
        }
        .sheet(item: $router.sheet) { destination in
            switch destination {
            case .createRoutine:
                RoutineEditorView(model: RoutineEditorModel(store: store))
            case let .trainingSession(routineID, sessionID):
                TrainingSessionEditorView(
                    model: TrainingSessionEditorModel(
                        store: store,
                        routineID: routineID,
                        sessionID: sessionID
                    )
                )
            case let .exercise(routineID, dayID, exerciseID):
                ExerciseEditorView(
                    model: ExerciseEditorModel(
                        store: store,
                        routineID: routineID,
                        dayID: dayID,
                        exerciseID: exerciseID
                    )
                )
            }
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.json],
            onCompletion: handleImport
        )
        .safeAreaInset(edge: .bottom) {
            if let importStatus {
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
    }

    private func handleImport(_ result: Result<URL, any Error>) {
        switch result {
        case .success(let url):
            let accessed = url.startAccessingSecurityScopedResource()
            defer {
                if accessed {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            do {
                try store.importSnapshot(from: Data(contentsOf: url))
                importStatus = FitnessImportStatus(
                    message: "Fitness data imported.",
                    isError: false
                )
            } catch {
                importStatus = FitnessImportStatus(
                    message: (error as? LocalizedError)?.errorDescription ?? error.localizedDescription,
                    isError: true
                )
            }
        case .failure(let error):
            if let cocoaError = error as? CocoaError,
               cocoaError.code == .userCancelled {
                return
            }
            importStatus = FitnessImportStatus(
                message: error.localizedDescription,
                isError: true
            )
        }
    }
}

private struct FitnessImportStatus {
    let message: String
    let isError: Bool
}

private struct RoutineListView: View {
    let store: FitnessStore
    let router: FitnessRouter
    let onImport: () -> Void

    var body: some View {
        Group {
            if store.snapshot.routines.isEmpty {
                ContentUnavailableView {
                    Label("No Routines Yet", systemImage: "figure.strengthtraining.traditional")
                        .accessibilityIdentifier(FitnessAccessibility.emptyRoutineList)
                } description: {
                    Text("Create a simple weekly routine. Everything stays on this device.")
                } actions: {
                    Button("Create Routine") {
                        router.sheet = .createRoutine
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier(FitnessAccessibility.createRoutineButton)
                }
            } else {
                List(store.snapshot.routines) { routine in
                    NavigationLink(value: FitnessRoute.routine(routine.id)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(routine.name)
                                .font(.headline)

                            if let notes = routine.notes {
                                Text(notes)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .accessibilityIdentifier("\(FitnessAccessibility.routineRow).\(routine.id.uuidString)")
                }
            }
        }
        .navigationTitle("Routines")
        .toolbar {
            ToolbarItem(placement: .secondaryAction) {
                Button(action: onImport) {
                    Label("Import Fitness Data", systemImage: "square.and.arrow.down")
                }
                .accessibilityIdentifier(SuperAppAccessibility.fitnessImportButton)
            }

            if !store.snapshot.routines.isEmpty {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        router.sheet = .createRoutine
                    } label: {
                        Label("Create Routine", systemImage: "plus")
                    }
                    .accessibilityIdentifier(FitnessAccessibility.createRoutineButton)
                }
            }
        }
    }
}

private struct RoutineEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model: RoutineEditorModel

    init(model: RoutineEditorModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        @Bindable var model = model

        NavigationStack {
            Form {
                Section("Routine") {
                    TextField("Name", text: $model.name)
                        .textInputAutocapitalization(.words)
                        .accessibilityIdentifier(FitnessAccessibility.routineNameField)

                    TextField("Notes (optional)", text: $model.notes, axis: .vertical)
                        .lineLimit(3...6)
                        .accessibilityIdentifier(FitnessAccessibility.routineNotesField)
                }

                if let validationMessage = model.validationMessage {
                    Section {
                        Text(validationMessage)
                            .foregroundStyle(XQPalette.destructive)
                            .accessibilityIdentifier(FitnessAccessibility.editorError)
                    }
                }

                Section {
                    Text("Saved locally on this device. Online sync can be added later without changing this flow.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("New Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if model.save() {
                            dismiss()
                        }
                    }
                    .disabled(!model.canSave)
                    .accessibilityIdentifier(FitnessAccessibility.routineSaveButton)
                }
            }
        }
    }
}

private struct TrainingSessionEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model: TrainingSessionEditorModel

    init(model: TrainingSessionEditorModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        @Bindable var model = model

        NavigationStack {
            Form {
                Section("Training Session") {
                    TextField("Name", text: $model.name)
                        .textInputAutocapitalization(.words)
                        .accessibilityIdentifier(FitnessAccessibility.trainingSessionNameField)
                }

                if let validationMessage = model.validationMessage {
                    Section {
                        Text(validationMessage)
                            .foregroundStyle(XQPalette.destructive)
                            .accessibilityIdentifier(FitnessAccessibility.editorError)
                    }
                }
            }
            .navigationTitle(model.isEditing ? "Rename Session" : "New Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if model.save() {
                            dismiss()
                        }
                    }
                    .disabled(!model.canSave)
                    .accessibilityIdentifier(FitnessAccessibility.trainingSessionSaveButton)
                }
            }
        }
    }
}

#Preview("Empty routines") {
    let store = try! FitnessStore(persistence: InMemoryFitnessPersistence())
    return FitnessRootView(store: store)
}
