import FitnessCore
import SwiftUI

struct ExerciseEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model: ExerciseEditorModel

    init(model: ExerciseEditorModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        @Bindable var model = model

        NavigationStack {
            Form {
                Section("Exercise") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Exercise name")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier(FitnessAccessibility.exerciseNameLabel)
                        TextField("e.g. Bench Press", text: $model.name)
                            .textInputAutocapitalization(.words)
                            .accessibilityLabel("Exercise name")
                            .accessibilityIdentifier(FitnessAccessibility.exerciseNameField)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Sets")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier(FitnessAccessibility.exerciseSetsLabel)
                        TextField("Number of sets", value: $model.sets, format: .number)
                            .keyboardType(.numberPad)
                            .accessibilityLabel("Sets")
                            .accessibilityIdentifier(FitnessAccessibility.exerciseSetsField)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Repetitions")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier(FitnessAccessibility.exerciseRepsLabel)
                        TextField("Repetitions per set", value: $model.reps, format: .number)
                            .keyboardType(.numberPad)
                            .accessibilityLabel("Repetitions")
                            .accessibilityIdentifier(FitnessAccessibility.exerciseRepsField)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Weight (kg)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier(FitnessAccessibility.exerciseWeightLabel)
                        TextField("Weight in kilograms", value: $model.weightKg, format: .number)
                            .keyboardType(.decimalPad)
                            .accessibilityLabel("Weight (kg)")
                            .accessibilityIdentifier(FitnessAccessibility.exerciseWeightField)
                    }
                }

                if let validationMessage = model.validationMessage {
                    Section {
                        Text(validationMessage)
                            .foregroundStyle(XQPalette.destructive)
                            .accessibilityIdentifier(FitnessAccessibility.editorError)
                    }
                }

                Section {
                    Text("Snapshots compare the highest reps and weight recorded for exercises with the same name across the routine.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(model.isEditing ? "Edit Exercise" : "Add Exercise")
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
                    .accessibilityIdentifier(FitnessAccessibility.exerciseSaveButton)
                }
            }
        }
    }
}

