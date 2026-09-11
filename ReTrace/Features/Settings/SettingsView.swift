import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.modelContext) private var modelContext

    @State private var showingDeleteAllConfirmation = false
    @State private var didDeleteAll = false

    var body: some View {
        @Bindable var settings = container.settingsStore

        Form {
            Section(String(localized: "Appearance")) {
                Picker(String(localized: "Appearance"), selection: $settings.colorSchemePreference) {
                    ForEach(RTColorSchemePreference.allCases, id: \.self) { option in
                        Text(option.displayName).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("settings.appearancePicker")
            }

            Section(String(localized: "Media")) {
                Picker(String(localized: "Image Quality"), selection: $settings.imageQuality) {
                    ForEach(RTImageQuality.allCases, id: \.self) { option in
                        Text(option.displayName).tag(option)
                    }
                }
                .accessibilityIdentifier("settings.imageQualityPicker")
            }

            Section(String(localized: "Data")) {
                Button(role: .destructive) {
                    showingDeleteAllConfirmation = true
                } label: {
                    Text("Delete All Data")
                }
                .accessibilityIdentifier("settings.deleteAllDataButton")
            }

            Section(String(localized: "Privacy")) {
                Text("All ReTrace projects are stored on this device.")
                    .font(RTTypography.secondary)
                    .foregroundStyle(RTColors.textSecondary)
            }

            Section(String(localized: "About")) {
                LabeledContent(String(localized: "Version"), value: appVersion)
                Text("ReTrace stores your own reference steps. It does not replace manufacturer instructions or professional safety guidance.")
                    .font(RTTypography.metadata)
                    .foregroundStyle(RTColors.textTertiary)
            }
        }
        .navigationTitle("Settings")
        .confirmationDialog(
            "Delete all projects, steps, parts, and photos? This can't be undone.",
            isPresented: $showingDeleteAllConfirmation,
            titleVisibility: .visible
        ) {
            Button(String(localized: "Delete All Data"), role: .destructive) {
                deleteAllData()
            }
            .accessibilityIdentifier("settings.confirmDeleteAllButton")
            Button(String(localized: "Cancel"), role: .cancel) {}
        }
        .alert(String(localized: "All Data Deleted"), isPresented: $didDeleteAll) {
            Button(String(localized: "OK"), role: .cancel) {}
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private func deleteAllData() {
        let descriptor = FetchDescriptor<RTProject>()
        guard let projects = try? modelContext.fetch(descriptor) else { return }
        let service = container.mutationService(context: modelContext)
        for project in projects {
            service.deleteProject(project)
        }
        didDeleteAll = true
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environment(AppContainer.makePreview())
}
