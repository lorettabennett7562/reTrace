import SwiftData
import SwiftUI

struct ProjectCreationView: View {
    @Environment(AppContainer.self) private var container
    @Environment(AppRouter.self) private var router
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var category: RTProjectCategory?
    @State private var notes = ""

    private var quickExamples: [ProjectTemplate] {
        guard !LaunchEnvironment.isUITesting,
              let decision = container.launchDecisionStore.decision,
              decision.flow == .native, let templates = decision.projectTemplates else {
            return ProjectTemplate.defaults
        }
        return templates
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(String(localized: "Project Name"), text: $title)
                        .accessibilityIdentifier("project.titleField")
                } header: {
                    Text("Project Name")
                }

                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: RTSpacing.xs) {
                            ForEach(quickExamples, id: \.self) { example in
                                RTFilterChip(title: example.title, isSelected: title == example.title) {
                                    title = example.title
                                    category = example.category
                                }
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets())
                    .padding(.horizontal, RTSpacing.md)
                    .padding(.vertical, RTSpacing.xxs)
                }

                Section(String(localized: "Category (optional)")) {
                    Picker(String(localized: "Category"), selection: $category) {
                        Text(String(localized: "None")).tag(RTProjectCategory?.none)
                        ForEach(RTProjectCategory.allCases) { option in
                            Label(option.displayName, systemImage: option.symbolName).tag(RTProjectCategory?.some(option))
                        }
                    }
                    .accessibilityIdentifier("project.categoryPicker")
                }

                Section(String(localized: "Notes (optional)")) {
                    TextField(String(localized: "Notes"), text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("New Project")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Start Capture")) {
                        startCapture()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityIdentifier("project.startCaptureButton")
                }
            }
        }
    }

    private func startCapture() {
        let service = container.mutationService(context: modelContext)
        let project = service.createProject(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category ?? .other,
            notes: notes.isEmpty ? nil : notes
        )
        try? service.startCapture(project)
        dismiss()
        router.continueCapture(for: project.id)
    }
}

#Preview {
    ProjectCreationView()
        .environment(AppContainer.makePreview())
        .environment(AppRouter())
}
