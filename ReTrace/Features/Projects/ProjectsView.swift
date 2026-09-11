import SwiftData
import SwiftUI

enum ProjectCategoryFilter: Hashable, Identifiable {
    case all
    case category(RTProjectCategory)

    var id: String {
        switch self {
        case .all: return "all"
        case .category(let category): return category.rawValue
        }
    }

    var title: String {
        switch self {
        case .all: return String(localized: "All")
        case .category(let category): return category.displayName
        }
    }
}

struct ProjectsView: View {
    @Environment(AppRouter.self) private var router
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @Query(sort: \RTProject.updatedAt, order: .reverse) private var allProjects: [RTProject]

    @State private var searchText = ""
    @State private var categoryFilter: ProjectCategoryFilter = .all
    @State private var showingCreateProject = false

    private var searchedProjects: [RTProject] {
        ProjectSearchEngine.search(allProjects, query: searchText)
    }

    private var filteredProjects: [RTProject] {
        switch categoryFilter {
        case .all: return searchedProjects
        case .category(let category): return searchedProjects.filter { $0.category == category }
        }
    }

    private var favorites: [RTProject] { filteredProjects.filter(\.isFavorite) }
    private var active: [RTProject] { filteredProjects.filter { $0.status == .draft || $0.status == .capturing } }
    private var readyToRestore: [RTProject] { filteredProjects.filter { $0.status == .disassembled || $0.status == .restoring } }
    private var completed: [RTProject] { filteredProjects.filter { $0.status == .completed || $0.status == .archived } }

    var body: some View {
        Group {
            if allProjects.isEmpty {
                emptyState
            } else {
                ReadableWidthContainer {
                    List {
                        categoryFilterSection
                        section(title: String(localized: "Favorites"), projects: favorites)
                        section(title: String(localized: "Active"), projects: active)
                        section(title: String(localized: "Ready to Restore"), projects: readyToRestore)
                        section(title: String(localized: "Completed"), projects: completed)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .navigationTitle("Projects")
        .searchable(text: $searchText, prompt: String(localized: "Search projects"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingCreateProject = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityIdentifier("projects.newProjectButton")
            }
        }
        .background(RTColors.background)
        .sheet(isPresented: $showingCreateProject) {
            ProjectCreationView()
        }
    }

    @ViewBuilder
    private var categoryFilterSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: RTSpacing.xs) {
                    RTFilterChip(title: ProjectCategoryFilter.all.title, isSelected: categoryFilter == .all) {
                        categoryFilter = .all
                    }
                    ForEach(RTProjectCategory.allCases) { category in
                        RTFilterChip(
                            title: category.displayName,
                            isSelected: categoryFilter == .category(category)
                        ) {
                            categoryFilter = .category(category)
                        }
                    }
                }
            }
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
    }

    @ViewBuilder
    private func section(title: String, projects: [RTProject]) -> some View {
        if !projects.isEmpty {
            Section(title) {
                ForEach(projects) { project in
                    Button {
                        router.openProjectDetail(project.id)
                    } label: {
                        ProjectListRow(project: project)
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: RTSpacing.sm) {
            Spacer()
            Image(systemName: "square.stack.3d.up")
                .font(.system(size: 40))
                .foregroundStyle(RTColors.textSecondary)
            Text("Nothing here yet.")
                .font(RTTypography.cardTitle)
            Text("Create a project before you disconnect,\nremove, or take something apart.")
                .font(RTTypography.secondary)
                .foregroundStyle(RTColors.textSecondary)
                .multilineTextAlignment(.center)
            Button(String(localized: "New Project")) {
                showingCreateProject = true
            }
            .buttonStyle(.rtPrimary)
            .padding(.horizontal, RTSpacing.xxl)
            .padding(.top, RTSpacing.xs)
            .accessibilityIdentifier("projects.newProjectButton.empty")
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(RTColors.background)
    }
}

#Preview {
    NavigationStack {
        ProjectsView()
    }
    .environment(AppContainer.makePreview())
    .environment(AppRouter())
}
