import SwiftData
import SwiftUI

enum TimelineDisplayMode {
    case photos
    case diagram
}

struct ProjectDetailView: View {
    let projectID: UUID

    @Environment(AppContainer.self) private var container
    @Environment(AppRouter.self) private var router
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var projects: [RTProject]
    @State private var showingDeleteConfirmation = false
    @State private var exportedURL: IdentifiableURL?
    @State private var exportErrorMessage: String?
    @State private var showingReminderSheet = false
    @State private var timelineDisplayMode: TimelineDisplayMode = .photos

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
        .navigationTitle(project?.title ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let project {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            project.isFavorite.toggle()
                        } label: {
                            Label(project.isFavorite ? "Remove Favorite" : "Add Favorite", systemImage: "star")
                        }
                        Button {
                            exportProject(project)
                        } label: {
                            Label("Export as PDF", systemImage: "square.and.arrow.up")
                        }
                        .accessibilityIdentifier("projectDetail.exportButton")
                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Delete Project", systemImage: "trash")
                        }
                        .accessibilityIdentifier("projectDetail.deleteButton")
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityIdentifier("projectDetail.menuButton")
                }
            }
        }
        .confirmationDialog(
            "Delete this project?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(String(localized: "Delete"), role: .destructive) {
                if let project { deleteProject(project) }
            }
            .accessibilityIdentifier("projectDetail.confirmDeleteButton")
            Button(String(localized: "Cancel"), role: .cancel) {}
        } message: {
            Text("This removes all steps, parts, connections, and photos. This can't be undone.")
        }
        .sheet(item: $exportedURL) { wrapper in
            ShareSheet(activityItems: [wrapper.url])
        }
        .sheet(isPresented: $showingReminderSheet) {
            if let project {
                ReminderSheet(project: project)
            }
        }
        .alert(String(localized: "Export Failed"), isPresented: Binding(
            get: { exportErrorMessage != nil },
            set: { if !$0 { exportErrorMessage = nil } }
        )) {
            Button(String(localized: "OK"), role: .cancel) {}
        } message: {
            Text(exportErrorMessage ?? "")
        }
    }

    @ViewBuilder
    private func content(for project: RTProject) -> some View {
        ScrollView {
            ReadableWidthContainer {
                VStack(alignment: .leading, spacing: RTSpacing.lg) {
                    header(for: project)
                    primaryActionButton(for: project)

                    if project.status == .disassembled || project.status == .restoring {
                        Button {
                            showingReminderSheet = true
                        } label: {
                            Label(String(localized: "Remind Me to Restore This"), systemImage: "bell")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.rtSecondary)
                        .accessibilityIdentifier("projectDetail.remindMeButton")
                    }

                    if let notes = project.notes, !notes.isEmpty {
                        RTCard {
                            VStack(alignment: .leading, spacing: RTSpacing.xxs) {
                                Text("Notes").font(RTTypography.cardTitle)
                                Text(notes).font(RTTypography.body).foregroundStyle(RTColors.textSecondary)
                            }
                        }
                    }

                    if project.restoreSteps.contains(where: \.isRestoreCompleted) || project.status == .restoring {
                        restoreProgress(for: project)
                    }

                    timeline(for: project)
                }
                .padding(RTSpacing.md)
            }
        }
        .background(RTColors.background)
    }

    private func header(for project: RTProject) -> some View {
        VStack(alignment: .leading, spacing: RTSpacing.xs) {
            HStack {
                RTStatusBadge(text: project.status.displayName, tint: RTColors.accentSecondary)
                Spacer()
                Text(project.createdAt, style: .date)
                    .font(RTTypography.metadata)
                    .foregroundStyle(RTColors.textTertiary)
            }
            HStack(spacing: RTSpacing.md) {
                Label("\(project.steps.count) steps", systemImage: "square.stack.3d.up")
                Label("\(project.parts.count) parts", systemImage: "shippingbox")
            }
            .font(RTTypography.secondary)
            .foregroundStyle(RTColors.textSecondary)
        }
    }

    @ViewBuilder
    private func primaryActionButton(for project: RTProject) -> some View {
        switch project.status {
        case .draft, .capturing:
            Button(String(localized: "Continue Capture")) {
                router.continueCapture(for: project.id)
            }
            .buttonStyle(.rtPrimary)
            .accessibilityIdentifier("projectDetail.continueCaptureButton")
        case .disassembled:
            Button(String(localized: "Start Restore")) {
                router.openRestore(for: project.id)
            }
            .buttonStyle(.rtPrimary)
            .accessibilityIdentifier("projectDetail.startRestoreButton")
        case .restoring:
            Button(String(localized: "Continue Restore")) {
                router.openRestore(for: project.id)
            }
            .buttonStyle(.rtPrimary)
            .accessibilityIdentifier("projectDetail.continueRestoreButton")
        case .completed, .archived:
            Button(String(localized: "View Completed Project")) {
                router.openRestore(for: project.id)
            }
            .buttonStyle(.rtSecondary)
            .accessibilityIdentifier("projectDetail.viewCompletedButton")
        }
    }

    private func restoreProgress(for project: RTProject) -> some View {
        let total = project.steps.count
        let done = project.completedRestoreStepCount
        return RTCard {
            VStack(alignment: .leading, spacing: RTSpacing.xs) {
                Text("Restore Progress").font(RTTypography.cardTitle)
                ProgressView(value: total == 0 ? 0 : Double(done) / Double(total))
                    .tint(RTColors.accent)
                Text("\(done) of \(total) completed")
                    .font(RTTypography.metadata)
                    .foregroundStyle(RTColors.textSecondary)
            }
        }
    }

    private func timeline(for project: RTProject) -> some View {
        VStack(alignment: .leading, spacing: RTSpacing.sm) {
            HStack {
                Text("Timeline").font(RTTypography.sectionTitle)
                Spacer()
                if !project.steps.isEmpty {
                    Picker(String(localized: "Timeline Display"), selection: $timelineDisplayMode) {
                        Image(systemName: "photo.on.rectangle").tag(TimelineDisplayMode.photos)
                        Image(systemName: "flowchart").tag(TimelineDisplayMode.diagram)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 100)
                    .accessibilityIdentifier("projectDetail.timelineDisplayPicker")
                }
            }
            if project.steps.isEmpty {
                Text("No steps recorded.")
                    .font(RTTypography.secondary)
                    .foregroundStyle(RTColors.textSecondary)
            } else if timelineDisplayMode == .diagram {
                StepFlowDiagramView(steps: project.orderedSteps)
            } else {
                ForEach(Array(project.orderedSteps.enumerated()), id: \.element.id) { index, step in
                    RTCard {
                        StepTimelineRow(step: step, position: index + 1)
                    }
                }
            }
        }
    }

    private func deleteProject(_ project: RTProject) {
        let service = container.mutationService(context: modelContext)
        service.deleteProject(project)
        dismiss()
    }

    private func exportProject(_ project: RTProject) {
        let model = PDFExportModelBuilder.build(from: project)
        do {
            let url = try container.exporter.export(model, mediaStore: container.mediaStore)
            exportedURL = IdentifiableURL(url: url)
        } catch {
            exportErrorMessage = String(localized: "Could not create the PDF. Please try again.")
        }
    }
}

struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}
