import PhotosUI
import SwiftData
import SwiftUI

struct CaptureView: View {
    @Environment(AppContainer.self) private var container
    @Environment(AppRouter.self) private var router
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \RTProject.updatedAt, order: .reverse) private var allProjects: [RTProject]

    @State private var pendingImageData: Data?
    @State private var selectedStepType: RTStepType = .reference
    @State private var noteText = ""
    @State private var isShowingAddPart = false
    @State private var isShowingAddConnection = false
    @State private var isShowingCamera = false
    @State private var isShowingCreateProject = false
    @State private var isSaving = false
    @State private var lastSavedStep: RTStep?
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var showingFinishConfirmation = false
    @FocusState private var isNoteFieldFocused: Bool

    private var activeProject: RTProject? {
        guard let id = router.activeProjectID else { return nil }
        return allProjects.first { $0.id == id }
    }

    private var continuableProjects: [RTProject] {
        allProjects.filter { $0.status == .draft || $0.status == .capturing }
    }

    var body: some View {
        Group {
            if let project = activeProject {
                captureContent(for: project)
            } else {
                startState
            }
        }
        .navigationTitle("Capture")
        .background(RTColors.background)
        .sheet(isPresented: $isShowingCreateProject) {
            ProjectCreationView()
        }
    }

    // MARK: - No active project

    private var startState: some View {
        ReadableWidthContainer {
            VStack(spacing: RTSpacing.lg) {
                Spacer()
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 48))
                    .foregroundStyle(RTColors.textSecondary)
                Text("Start capturing")
                    .font(RTTypography.sectionTitle)
                Text("Create a new project, or continue one you already started.")
                    .font(RTTypography.secondary)
                    .foregroundStyle(RTColors.textSecondary)
                    .multilineTextAlignment(.center)

                Button(String(localized: "Start New Project")) {
                    isShowingCreateProject = true
                }
                .buttonStyle(.rtPrimary)
                .accessibilityIdentifier("capture.newProjectButton")

                if !continuableProjects.isEmpty {
                    VStack(alignment: .leading, spacing: RTSpacing.xs) {
                        Text("Continue a project")
                            .font(RTTypography.cardTitle)
                        ForEach(continuableProjects) { project in
                            Button {
                                router.continueCapture(for: project.id)
                            } label: {
                                ProjectListRow(project: project)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, RTSpacing.lg)
                }
                Spacer()
            }
            .padding(RTSpacing.lg)
        }
    }

    // MARK: - Active capture

    @ViewBuilder
    private func captureContent(for project: RTProject) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: RTSpacing.md) {
                    header(for: project)
                    previewArea(for: project)

                    Text("Photo (optional)")
                        .font(RTTypography.metadata.weight(.semibold))
                        .foregroundStyle(RTColors.textTertiary)
                    photoActionsRow

                    stepTypePicker
                    noteField

                    secondaryActionsRow

                    if project.steps.count > 0 {
                        finishDisassemblyButton(for: project)
                    }
                }
                .padding(RTSpacing.md)
            }

            Divider()
            saveStepButton(for: project)
                .padding(RTSpacing.md)
                .background(RTColors.background)
        }
        .fullScreenCover(isPresented: $isShowingCamera) {
            CameraCaptureView(
                onCapture: { data in
                    pendingImageData = data
                    isShowingCamera = false
                },
                onCancel: { isShowingCamera = false }
            )
            .ignoresSafeArea()
        }
        .sheet(isPresented: $isShowingAddPart) {
            AddPartSheet(project: project, linkedStep: lastSavedStep)
        }
        .sheet(isPresented: $isShowingAddConnection) {
            AddConnectionSheet(project: project, linkedStepID: lastSavedStep?.id)
        }
        .confirmationDialog(
            "Finish disassembly for this project?",
            isPresented: $showingFinishConfirmation,
            titleVisibility: .visible
        ) {
            Button(String(localized: "Finish Disassembly")) {
                finishDisassembly(project)
            }
            .accessibilityIdentifier("capture.confirmFinishButton")
            Button(String(localized: "Cancel"), role: .cancel) {}
        }
    }

    private func header(for project: RTProject) -> some View {
        VStack(alignment: .leading, spacing: RTSpacing.xxs) {
            Text(project.title)
                .font(RTTypography.projectTitle)
            // Always the step currently being composed — one past however
            // many are already saved — regardless of whether a photo is
            // pending, since a photo is no longer required to start one.
            Text("Step \(project.steps.count + 1)")
                .font(RTTypography.secondary)
                .foregroundStyle(RTColors.textSecondary)
        }
    }

    @ViewBuilder
    private func previewArea(for project: RTProject) -> some View {
        RTCard {
            VStack(spacing: RTSpacing.sm) {
                if let data = pendingImageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 320)
                        .clipShape(RoundedRectangle(cornerRadius: RTRadius.control, style: .continuous))
                } else if project.steps.isEmpty {
                    VStack(spacing: RTSpacing.xs) {
                        Image(systemName: "square.stack.3d.up")
                            .font(.system(size: 32))
                            .foregroundStyle(RTColors.textTertiary)
                        Text("Ready when you are.")
                            .font(RTTypography.secondary)
                            .foregroundStyle(RTColors.textSecondary)
                        Text("A photo helps, but it's not required — a type and a note below are enough.")
                            .font(RTTypography.metadata)
                            .foregroundStyle(RTColors.textTertiary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, minHeight: 140)
                } else {
                    Text("Ready for the next step — add a photo, or just fill in the note below.")
                        .font(RTTypography.secondary)
                        .foregroundStyle(RTColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, minHeight: 80)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    /// Photo is one optional way to document a step, not a requirement —
    /// `stepTypePicker` + `noteField` below work with no photo at all, so a
    /// step can be recorded purely as text when a picture isn't practical.
    private var photoActionsRow: some View {
        HStack(spacing: RTSpacing.sm) {
            Button {
                takePhoto()
            } label: {
                Label(String(localized: "Take Photo"), systemImage: "camera.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.rtSecondary)
            .accessibilityIdentifier("capture.takePhotoButton")

            PhotosPicker(selection: $photosPickerItem, matching: .images) {
                Label(String(localized: "Choose Photo"), systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.rtSecondary)
            .accessibilityIdentifier("capture.choosePhotoButton")
            .onChange(of: photosPickerItem) { _, newValue in
                guard let newValue else { return }
                Task {
                    if let data = try? await newValue.loadTransferable(type: Data.self) {
                        pendingImageData = data
                    }
                    photosPickerItem = nil
                }
            }

            if pendingImageData != nil {
                Button(role: .destructive) {
                    pendingImageData = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                }
                .accessibilityIdentifier("capture.clearPhotoButton")
                .accessibilityLabel("Remove photo")
            }
        }
    }

    private var secondaryActionsRow: some View {
        HStack(spacing: RTSpacing.sm) {
            Button {
                isShowingAddPart = true
            } label: {
                Label(String(localized: "Add Part"), systemImage: "shippingbox")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.rtSecondary)
            .accessibilityIdentifier("capture.addPartButton")

            Button {
                isShowingAddConnection = true
            } label: {
                Label(String(localized: "Add Connection"), systemImage: "arrow.left.arrow.right")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.rtSecondary)
            .accessibilityIdentifier("capture.addConnectionButton")
        }
    }

    private var stepTypePicker: some View {
        VStack(alignment: .leading, spacing: RTSpacing.xs) {
            Text("What did you do?")
                .font(RTTypography.cardTitle)
            Text("A photo is optional — a type and a note are enough to record a step.")
                .font(RTTypography.metadata)
                .foregroundStyle(RTColors.textTertiary)
            // A wrapping grid rather than a horizontal scroll: every option
            // stays on screen at once, so nothing is hidden off to the side.
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: RTSpacing.xs)], alignment: .leading, spacing: RTSpacing.xs) {
                ForEach(RTStepType.allCases) { type in
                    RTFilterChip(title: type.displayName, isSelected: selectedStepType == type) {
                        selectedStepType = type
                    }
                    .accessibilityIdentifier("capture.stepType.\(type.rawValue)")
                }
            }
        }
    }

    private var noteField: some View {
        TextField(String(localized: "Short note (optional)"), text: $noteText, axis: .vertical)
            .textFieldStyle(.roundedBorder)
            .lineLimit(2...4)
            .focused($isNoteFieldFocused)
            .accessibilityIdentifier("capture.noteField")
    }

    private var hasRecordableContent: Bool {
        pendingImageData != nil || !noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func saveStepButton(for project: RTProject) -> some View {
        Button {
            saveStep(for: project)
        } label: {
            if isSaving {
                ProgressView().frame(maxWidth: .infinity)
            } else {
                Text("Save Step").frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.rtPrimary)
        .disabled(isSaving || !hasRecordableContent)
        .accessibilityIdentifier("capture.saveStepButton")
    }

    private func finishDisassemblyButton(for project: RTProject) -> some View {
        Button(String(localized: "Finish Disassembly")) {
            showingFinishConfirmation = true
        }
        .buttonStyle(.rtSecondary)
        .accessibilityIdentifier("capture.finishButton")
    }

    // MARK: - Actions

    private func takePhoto() {
        if LaunchEnvironment.useMockCamera || !CameraAvailability.isAvailable {
            pendingImageData = MockCameraProvider.placeholderImageData()
        } else {
            isShowingCamera = true
        }
    }

    /// A photo is one optional way to document a step — this saves a step
    /// from whatever the user provided (photo, note, or both), so a step
    /// recorded purely as text is just as valid as a photographed one.
    private func saveStep(for project: RTProject) {
        guard !isSaving, hasRecordableContent else { return }
        isSaving = true
        let type = selectedStepType
        let note = noteText
        let data = pendingImageData
        Task {
            var imagePath: String?
            var thumbnailPath: String?
            if let data {
                let quality = container.settingsStore.imageQuality
                let processed = await ImageProcessing.processedOriginal(from: data, quality: quality) ?? data
                let thumbnailData = container.thumbnailGenerator.makeThumbnail(from: processed, maxDimension: 320)
                let mediaID = UUID()
                imagePath = try? container.mediaStore.saveOriginal(processed, projectID: project.id, mediaID: mediaID)
                thumbnailPath = thumbnailData.flatMap { try? container.mediaStore.saveThumbnail($0, projectID: project.id, mediaID: mediaID) }
            }

            let service = container.mutationService(context: modelContext)
            let step = service.addStep(
                to: project,
                note: note.isEmpty ? nil : note,
                stepType: type,
                imagePath: imagePath,
                thumbnailPath: thumbnailPath
            )

            lastSavedStep = step
            pendingImageData = nil
            noteText = ""
            selectedStepType = .reference
            isSaving = false
            isNoteFieldFocused = false
        }
    }

    private func finishDisassembly(_ project: RTProject) {
        let service = container.mutationService(context: modelContext)
        try? service.finishDisassembly(project)
        router.activeProjectID = nil
        router.openProjectDetail(project.id, from: .projects)
    }
}

#Preview {
    NavigationStack {
        CaptureView()
    }
    .environment(AppContainer.makePreview())
    .environment(AppRouter())
}
