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
                    ScrollView {
                        VStack(alignment: .leading, spacing: RTSpacing.md) {
                            categoryFilterBar
                            VStack(alignment: .leading, spacing: RTSpacing.md) {
                                section(title: String(localized: "Favorites"), projects: favorites)
                                section(title: String(localized: "Active"), projects: active)
                                section(title: String(localized: "Ready to Restore"), projects: readyToRestore)
                                section(title: String(localized: "Completed"), projects: completed)
                            }
                            .padding(.horizontal, RTSpacing.md)
                        }
                    }
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

    private var categoryFilterBar: some View {
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
        .contentMargins(.horizontal, RTSpacing.md, for: .scrollContent)
    }

    @ViewBuilder
    private func section(title: String, projects: [RTProject]) -> some View {
        if !projects.isEmpty {
            VStack(alignment: .leading, spacing: RTSpacing.xs) {
                Text(title)
                    .font(RTTypography.secondary)
                    .fontWeight(.semibold)
                    .foregroundStyle(RTColors.textSecondary)
                    .accessibilityAddTraits(.isHeader)
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 300), spacing: RTSpacing.sm, alignment: .top)],
                    spacing: RTSpacing.sm
                ) {
                    ForEach(projects) { project in
                        Button {
                            router.openProjectDetail(project.id)
                        } label: {
                            ProjectListRow(project: project)
                        }
                        .buttonStyle(.plain)
                    }
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
