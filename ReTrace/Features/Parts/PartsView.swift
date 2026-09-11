import SwiftData
import SwiftUI

struct PartsView: View {
    @Environment(AppRouter.self) private var router
    @Environment(AppContainer.self) private var container
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \RTProject.updatedAt, order: .reverse) private var projects: [RTProject]

    @State private var searchText = ""
    @State private var isShowingProjectPicker = false
    @State private var projectForNewPart: RTProject?

    private var projectsWithParts: [RTProject] {
        let filtered = projects.filter { !$0.parts.isEmpty }
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return filtered }
        let needle = searchText.lowercased()
        return filtered.filter { project in
            project.parts.contains { part in
                part.name.lowercased().contains(needle) || (part.storageLabel?.lowercased().contains(needle) ?? false)
            }
        }
    }

    var body: some View {
        Group {
            if projects.allSatisfy({ $0.parts.isEmpty }) {
                emptyState
            } else {
                List {
                    ForEach(projectsWithParts) { project in
                        Section(project.title) {
                            ForEach(project.parts.sorted(by: { $0.createdAt < $1.createdAt })) { part in
                                Button {
                                    router.openProjectDetail(project.id, from: .parts)
                                } label: {
                                    PartRow(part: part)
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("part.card.\(part.id.uuidString)")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .searchable(text: $searchText, prompt: String(localized: "Search parts"))
            }
        }
        .navigationTitle("Parts")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if projects.count == 1 {
                        projectForNewPart = projects.first
                    } else {
                        isShowingProjectPicker = true
                    }
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityIdentifier("parts.addButton")
                .disabled(projects.isEmpty)
            }
        }
        .background(RTColors.background)
        .confirmationDialog(String(localized: "Add part to which project?"), isPresented: $isShowingProjectPicker, titleVisibility: .visible) {
            ForEach(projects) { project in
                Button(project.title) { projectForNewPart = project }
            }
        }
        .sheet(item: $projectForNewPart) { project in
            AddPartSheet(project: project, linkedStep: nil)
        }
    }

    private var emptyState: some View {
        VStack(spacing: RTSpacing.sm) {
            Spacer()
            Image(systemName: "shippingbox")
                .font(.system(size: 40))
                .foregroundStyle(RTColors.textSecondary)
            Text("No parts recorded.")
                .font(RTTypography.cardTitle)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(RTColors.background)
    }
}

private struct PartRow: View {
    let part: RTPart

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(part.quantity)× \(part.name)")
                    .font(RTTypography.body)
                if let storage = part.storageLabel, !storage.isEmpty {
                    Text(storage)
                        .font(RTTypography.metadata)
                        .foregroundStyle(RTColors.textSecondary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 2)
    }
}
