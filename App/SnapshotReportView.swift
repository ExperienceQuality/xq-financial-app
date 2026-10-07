import FitnessCore
import SwiftUI

struct SnapshotReportView: View {
    let store: FitnessStore
    let routineID: UUID

    private var report: SnapshotReport? {
        try? store.snapshotReport(routineID: routineID)
    }

    var body: some View {
        Group {
            if let report {
                List {
                    Section {
                        LabeledContent("Captured", value: report.current.createdAt.formatted(
                            date: .abbreviated,
                            time: .shortened
                        ))
                        LabeledContent(
                            "Comparison",
                            value: report.previous == nil ? "First snapshot" : "Previous snapshot"
                        )
                    }

                    if report.exercises.isEmpty {
                        ContentUnavailableView(
                            "No Exercises Captured",
                            systemImage: "camera.metering.none",
                            description: Text("Add exercises to the routine before the next snapshot.")
                        )
                    } else {
                        Section("Exercise Progress") {
                            ForEach(report.exercises) { progress in
                                SnapshotExerciseRow(progress: progress)
                                    .accessibilityIdentifier(
                                        "\(FitnessAccessibility.snapshotExercise).\(progress.id)"
                                    )
                            }
                        }
                    }
                }
                .accessibilityIdentifier(FitnessAccessibility.snapshotReport)
            } else {
                ContentUnavailableView(
                    "No Snapshot Yet",
                    systemImage: "camera.aperture",
                    description: Text("Create a snapshot from the routine workspace.")
                )
            }
        }
        .navigationTitle("Snapshot")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SnapshotExerciseRow: View {
    let progress: ExerciseProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(progress.current.name)
                    .font(.headline)
                Spacer()
                Text("\(progress.current.sets) sets")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                ProgressMetric(
                    title: "Reps",
                    value: "\(progress.current.reps)",
                    indicator: progress.reps
                )
                ProgressMetric(
                    title: "Weight",
                    value: "\(progress.current.weightKg.formatted()) kg",
                    indicator: progress.weight
                )
            }
        }
        .padding(.vertical, 6)
    }
}

private struct ProgressMetric: View {
    let title: String
    let value: String
    let indicator: ProgressIndicator

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.bold().monospacedDigit())
            ProgressIndicatorBadge(indicator: indicator)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct ProgressIndicatorBadge: View {
    let indicator: ProgressIndicator

    var body: some View {
        Label(title, systemImage: symbol)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .accessibilityIdentifier("\(FitnessAccessibility.snapshotProgress).\(indicator.rawValue)")
    }

    private var title: String {
        switch indicator {
        case .first: "First snapshot"
        case .increased: "Increased"
        case .decreased: "Decreased"
        case .maintained: "Same"
        }
    }

    private var symbol: String {
        switch indicator {
        case .first: "minus"
        case .increased: "arrow.up.right"
        case .decreased: "arrow.down.right"
        case .maintained: "equal"
        }
    }

    private var color: Color {
        switch indicator {
        case .first, .maintained: .secondary
        case .increased: .green
        case .decreased: XQPalette.destructive
        }
    }
}

