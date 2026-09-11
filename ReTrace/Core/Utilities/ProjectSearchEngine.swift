import Foundation

/// Case-insensitive, whitespace-tolerant search across a project's name,
/// step titles/notes, part names/storage labels, and connection labels.
enum ProjectSearchEngine {
    static func matches(_ project: RTProject, query: String) -> Bool {
        let needle = normalize(query)
        guard !needle.isEmpty else { return true }

        if normalize(project.title).contains(needle) { return true }
        if let notes = project.notes, normalize(notes).contains(needle) { return true }

        for step in project.steps {
            if let title = step.title, normalize(title).contains(needle) { return true }
            if let note = step.note, normalize(note).contains(needle) { return true }
        }

        for part in project.parts {
            if normalize(part.name).contains(needle) { return true }
            if let storage = part.storageLabel, normalize(storage).contains(needle) { return true }
        }

        for connection in project.connections {
            if normalize(connection.fromLabel).contains(needle) { return true }
            if normalize(connection.toLabel).contains(needle) { return true }
            if let note = connection.note, normalize(note).contains(needle) { return true }
        }

        return false
    }

    static func search(_ projects: [RTProject], query: String) -> [RTProject] {
        guard !normalize(query).isEmpty else { return projects }
        return projects.filter { matches($0, query: query) }
    }

    private static func normalize(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
