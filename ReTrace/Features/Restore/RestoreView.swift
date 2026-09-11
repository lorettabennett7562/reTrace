import SwiftData
import SwiftUI

struct RestoreView: View {
    let projectID: UUID

    @Environment(AppContainer.self) private var container
    @Environment(AppRouter.self) private var router
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @Query private var projects: [RTProject]
    @State private var displayIndex = 0
    @State private var hasInitializedIndex = false
    @State private var showingCompleteConfirmation = false
    @State private var showingFinalComparison = false

    init(projectID: UUID) {
        self.projectID = projectID
        let predicate = #Predicate<RTProject> { $0.id == projectID }
        _projects = Query(filter: predicate)
    }

    private var project: RTProject? { projects.first }

    var body: some View {
        Group {
            if let project {
                content(for: project)
            } else {
                ContentUnavailableView(String(localized: "Project not found"), systemImage: "questionmark.folder")
            }
        }
        .navigationTitle("Restore")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard let project else { return }
            if project.status == .disassembled {
                try? container.mutationService(context: modelContext).startRestore(project)
            }
            if !hasInitializedIndex {
                displayIndex = initialIndex(for: project)
                hasInitializedIndex = true
            }
        }
        .sheet(isPresented: $showingFinalComparison) {
            if let project {
                FinalComparisonView(project: project)
            }
        }
    }

    @ViewBuilder
    private func content(for project: RTProject) -> some View {
        let restoreSteps = project.restoreSteps
        let allCompleted = !restoreSteps.isEmpty && restoreSteps.allSatisfy(\.isRestoreCompleted)

        if restoreSteps.isEmpty {
            ContentUnavailableView(String(localized: "No steps recorded"), systemImage: "square.stack.3d.up")
        } else if allCompleted {
            completionView(for: project)
        } else {
            stepView(for: project, restoreSteps: restoreSteps)
        }
    }

    // MARK: - Step-by-step

    @ViewBuilder
    private func stepView(for project: RTProject, restoreSteps: [RTStep]) -> some View {
        let clampedIndex = min(max(displayIndex, 0), restoreSteps.count - 1)
        let step = restoreSteps[clampedIndex]

        ReadableWidthContainer {
            ScrollView {
                VStack(alignment: .leading, spacing: RTSpacing.lg) {
                    VStack(alignment: .leading, spacing: RTSpacing.xxs) {
                        Text("Restore Step \(clampedIndex + 1) of \(restoreSteps.count)")
                            .font(RTTypography.secondary)
                            .foregroundStyle(RTColors.textSecondary)
                        Text("\(step.stepType.restoreVerb) \(step.displayTitle)")
                            .font(RTTypography.largeTitle)
                    }

                    RTStoredImage(path: step.imagePath) {
                        RoundedRectangle(cornerRadius: RTRadius.card, style: .continuous)
                            .fill(RTColors.surfaceSecondary)
                            .overlay {
                                Image(systemName: "photo").font(.system(size: 32)).foregroundStyle(RTColors.textTertiary)
                            }
                    }
                    .frame(maxWidth: .infinity, minHeight: 220, maxHeight: 320)
                    .clipShape(RoundedRectangle(cornerRadius: RTRadius.card, style: .continuous))
                    .accessibilityIdentifier("restore.referenceImage")

                    if let note = step.note, !note.isEmpty {
                        RTCard {
                            VStack(alignment: .leading, spacing: RTSpacing.xxs) {
                                Text("Recorded note").font(RTTypography.cardTitle)
                                Text(note).font(RTTypography.body).foregroundStyle(RTColors.textSecondary)
                            }
                        }
                    }

                    if !step.parts.isEmpty {
                        RTCard {
                            VStack(alignment: .leading, spacing: RTSpacing.xxs) {
                                Text("Parts").font(RTTypography.cardTitle)
                                ForEach(step.parts) { part in
                                    Text("\(part.quantity)× \(part.name)")
                                        .font(RTTypography.body)
                                        .foregroundStyle(RTColors.textSecondary)
                                }
                            }
                        }
                    }

                    if step.isRestoreCompleted {
                        Label(String(localized: "Completed"), systemImage: "checkmark.circle.fill")
                            .foregroundStyle(RTColors.success)
                    }

                    markDoneButton(for: project, step: step)

                    navigationRow(restoreStepCount: restoreSteps.count, clampedIndex: clampedIndex)
                }
                .padding(RTSpacing.md)
            }
        }
    }

    private func markDoneButton(for project: RTProject, step: RTStep) -> some View {
        Button(String(localized: "Mark Done")) {
            markDone(project: project, step: step)
        }
        .buttonStyle(.rtPrimary)
        .accessibilityIdentifier("restore.markDoneButton")
    }

    private func navigationRow(restoreStepCount: Int, clampedIndex: Int) -> some View {
        HStack(spacing: RTSpacing.sm) {
            Button(String(localized: "Previous")) {
                displayIndex = max(0, clampedIndex - 1)
            }
            .buttonStyle(.rtSecondary)
            .disabled(clampedIndex == 0)
            .accessibilityIdentifier("restore.previousButton")

            Button(String(localized: "Next")) {
                displayIndex = min(restoreStepCount - 1, clampedIndex + 1)
            }
            .buttonStyle(.rtSecondary)
            .disabled(clampedIndex == restoreStepCount - 1)
            .accessibilityIdentifier("restore.nextButton")
        }
    }

    // MARK: - Completion

    private func completionView(for project: RTProject) -> some View {
        ReadableWidthContainer {
            VStack(spacing: RTSpacing.lg) {
                Spacer()
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(RTColors.success)
                Text("Restoration complete")
                    .font(RTTypography.largeTitle)
                    .accessibilityIdentifier("restore.completionTitle")

                if project.status != .completed {
                    Button(String(localized: "Compare Final State")) {
                        showingFinalComparison = true
                    }
                    .buttonStyle(.rtSecondary)
                    .accessibilityIdentifier("restore.compareFinalStateButton")

                    Button(String(localized: "Complete Project")) {
                        showingCompleteConfirmation = true
                    }
                    .buttonStyle(.rtPrimary)
                    .accessibilityIdentifier("restore.completeProjectButton")
                } else {
                    Text("This project is complete.")
                        .font(RTTypography.secondary)
                        .foregroundStyle(RTColors.textSecondary)
                }
                Spacer()
            }
            .padding(RTSpacing.lg)
        }
        .confirmationDialog(
            "Mark this project as complete?",
            isPresented: $showingCompleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(String(localized: "Complete Project")) {
                try? container.mutationService(context: modelContext).completeProject(project)
                // Nothing more to do here — return to the project list rather
                // than leaving the tab stranded on this completion screen.
                router.projectsPath.removeAll()
            }
            .accessibilityIdentifier("restore.confirmCompleteButton")
            Button(String(localized: "Cancel"), role: .cancel) {}
        }
    }

    private func markDone(project: RTProject, step: RTStep) {
        container.mutationService(context: modelContext).markRestoreStepDone(step, done: true)
        let restoreSteps = project.restoreSteps
        if let index = restoreSteps.firstIndex(where: { $0.id == step.id }), index < restoreSteps.count - 1 {
            displayIndex = index + 1
        }
    }

    /// Resumes at the first not-yet-completed step, so relaunching mid-restore
    /// (see spec §95) returns the user to the correct place automatically —
    /// the position is derived from persisted `isRestoreCompleted` flags
    /// rather than stored separately.
    private func initialIndex(for project: RTProject) -> Int {
        let restoreSteps = project.restoreSteps
        return restoreSteps.firstIndex(where: { !$0.isRestoreCompleted }) ?? max(0, restoreSteps.count - 1)
    }
}
