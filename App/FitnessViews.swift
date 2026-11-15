import FitnessCore
import Foundation
import SwiftUI

enum FitnessImportTestHook {
    static let fixtureArgument = "--xq-fitness-import-fixture"

    static func fixtureURL(arguments: [String]) -> URL? {
        guard arguments.contains("--xq-ui-testing") else { return nil }
        if let inline = arguments.first(where: { $0.hasPrefix("\(fixtureArgument)=") }) {
            let path = String(inline.dropFirst(fixtureArgument.count + 1))
            return path.isEmpty ? nil : URL(fileURLWithPath: path)
        }
        guard let index = arguments.firstIndex(of: fixtureArgument),
              arguments.index(after: index) < arguments.endIndex else {
            return nil
        }
        let path = arguments[arguments.index(after: index)]
        return path.isEmpty ? nil : URL(fileURLWithPath: path)
    }
}

struct RoutineListView: View {
    @Bindable var viewModel: RoutineListViewModel

    var body: some View {
        Group {
            if viewModel.store.snapshot.routines.isEmpty {
                ContentUnavailableView {
                    Label("No Routines Yet", systemImage: "figure.strengthtraining.traditional")
                        .accessibilityIdentifier(FitnessAccessibility.emptyRoutineList)
                } description: {
                    Text("Create a simple weekly routine. Everything stays on this device.")
                } actions: {
                    Button("Create Routine") {
                        viewModel.showCreateRoutine()
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier(FitnessAccessibility.createRoutineButton)
                }
            } else {
                List(viewModel.store.snapshot.routines) { routine in
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
                Button(action: viewModel.showImportPicker) {
                    Label("Import Fitness Data", systemImage: "square.and.arrow.down")
                }
                .accessibilityIdentifier(SuperAppAccessibility.fitnessImportButton)
            }

            if !viewModel.store.snapshot.routines.isEmpty {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.showCreateRoutine()
                    } label: {
                        Label("Create Routine", systemImage: "plus")
                    }
                    .accessibilityIdentifier(FitnessAccessibility.createRoutineButton)
                }
            }
        }
    }
}

struct RoutineEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model: RoutineEditorModel
    let onSaved: () -> Void

    init(model: RoutineEditorModel, onSaved: @escaping () -> Void) {
        _model = State(initialValue: model)
        self.onSaved = onSaved
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
                            onSaved()
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

struct TrainingSessionEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model: TrainingSessionEditorModel
    let onSaved: () -> Void

    init(model: TrainingSessionEditorModel, onSaved: @escaping () -> Void) {
        _model = State(initialValue: model)
        self.onSaved = onSaved
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
                            onSaved()
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
    let coordinator = FitnessTabCoordinator()
    return FitnessCoordinatorView(store: store, coordinator: coordinator)
}
