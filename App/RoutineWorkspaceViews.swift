import FitnessCore
import SwiftUI

struct RoutineWorkspaceView: View {
    @Bindable var viewModel: RoutineWorkspaceViewModel

    var body: some View {
        Group {
            if let routine = viewModel.routine {
                List {
                    Section {
                        Button {
                            viewModel.createSnapshot()
                        } label: {
                            Label(
                                "Snapshot Progress",
                                systemImage: "camera.aperture"
                            )
                            .frame(
                                maxWidth: .infinity,
                                alignment: .center
                            )
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier(FitnessAccessibility.snapshotButton)

                        if !routine.snapshots.isEmpty {
                            NavigationLink(
                                value: FitnessRoute.snapshotReport(routineID: viewModel.routineID)
                            ) {
                                Label(
                                    "Latest Comparison",
                                    systemImage: "chart.line.uptrend.xyaxis"
                                )
                            }
                        }
                    } footer: {
                        Text(
                            "Snapshots stay on this device and compare exercise reps and weight with the previous capture."
                        )
                    }

                    Section("Training Sessions") {
                        if routine.days.isEmpty {
                            ContentUnavailableView {
                                Label(
                                    "No Training Sessions",
                                    systemImage: "figure.strengthtraining.traditional"
                                )
                            } description: {
                                Text("Add the sessions you want in this routine.")
                            } actions: {
                                addTrainingSessionButton
                            }
                        } else {
                            ForEach(
                                routine.days.sorted(using: KeyPathComparator(\.number))
                            ) { day in
                                NavigationLink(
                                    value: FitnessRoute.trainingDay(
                                        routineID: viewModel.routineID,
                                        dayID: day.id
                                    )
                                ) {
                                    TrainingDayRow(day: day)
                                }
                                .accessibilityIdentifier(
                                    "\(FitnessAccessibility.trainingDayRow).\(day.number)"
                                )
                                .swipeActions {
                                    Button("Rename") {
                                        viewModel.showRenameTrainingSession(day.id)
                                    }
                                    .tint(.blue)

                                    Button("Delete", role: .destructive) {
                                        viewModel.deleteTrainingSession(day)
                                    }
                                }
                            }
                        }
                    }
                }
                .accessibilityIdentifier(FitnessAccessibility.routineWorkspace)
                .navigationTitle(routine.name)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        addTrainingSessionButton
                    }
                }
            } else {
                ContentUnavailableView(
                    "Routine Unavailable",
                    systemImage: "exclamationmark.triangle"
                )
            }
        }
        .alert(
            "Could Not Update Routine",
            isPresented: errorIsPresented
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error")
        }
    }

    private var addTrainingSessionButton: some View {
        Button {
            viewModel.showAddTrainingSession()
        } label: {
            Label("Add Training Session", systemImage: "plus")
        }
        .accessibilityIdentifier(FitnessAccessibility.addTrainingSessionButton)
    }

    private var errorIsPresented: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: {
                if !$0 {
                    viewModel.errorMessage = nil
                }
            }
        )
    }
}

private struct TrainingDayRow: View {
    let day: TrainingDay

    var body: some View {
        HStack(spacing: 12) {
            Text(day.name.prefix(3).uppercased())
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(.blue.gradient, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(day.name)
                    .font(.headline)
                Text(
                    day.exercises.isEmpty
                        ? "Add exercises"
                        : "\(day.exercises.count) exercise\(day.exercises.count == 1 ? "" : "s")"
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 3)
    }
}

struct TrainingDayView: View {
    @Bindable var viewModel: TrainingDayViewModel

    var body: some View {
        Group {
            if let day = viewModel.day {
                List {
                    if day.exercises.isEmpty {
                        ContentUnavailableView {
                            Label("No Exercises", systemImage: "dumbbell")
                        } description: {
                            Text("Add the exercises planned for this training session.")
                        } actions: {
                            addExerciseButton
                        }
                    } else {
                        Section("Exercises") {
                            ForEach(day.exercises) { exercise in
                                Button {
                                    viewModel.showEditExercise(exercise.id)
                                } label: {
                                    ExerciseRow(exercise: exercise)
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier(
                                    "\(FitnessAccessibility.exerciseRow).\(exercise.id.uuidString)"
                                )
                                .swipeActions {
                                    Button("Delete", role: .destructive) {
                                        viewModel.deleteExercise(exercise)
                                    }
                                }
                            }
                        }
                    }
                }
                .accessibilityIdentifier(FitnessAccessibility.trainingDayScreen)
                .navigationTitle(day.name)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        addExerciseButton
                    }
                }
            } else {
                ContentUnavailableView(
                    "Training Session Unavailable",
                    systemImage: "calendar.badge.exclamationmark"
                )
            }
        }
        .alert(
            "Could Not Update Exercise",
            isPresented: errorIsPresented
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error")
        }
    }

    private var addExerciseButton: some View {
        Button {
            viewModel.showAddExercise()
        } label: {
            Label("Add Exercise", systemImage: "plus")
        }
        .accessibilityIdentifier(FitnessAccessibility.addExerciseButton)
    }

    private var errorIsPresented: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: {
                if !$0 {
                    viewModel.errorMessage = nil
                }
            }
        )
    }
}

private struct ExerciseRow: View {
    let exercise: Exercise

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(exercise.name)
                .font(.headline)
            Text("\(exercise.sets) × \(exercise.reps) @ \(exercise.weightKg.formatted()) kg")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
