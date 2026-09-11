import SwiftData
import SwiftUI

struct AddConnectionSheet: View {
    let project: RTProject
    let linkedStepID: UUID?

    @Environment(AppContainer.self) private var container
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var fromLabel = ""
    @State private var toLabel = ""
    @State private var note = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "Connection")) {
                    TextField(String(localized: "From (e.g. HDMI Cable)"), text: $fromLabel)
                        .accessibilityIdentifier("connection.fromField")
                    TextField(String(localized: "To (e.g. TV HDMI 2)"), text: $toLabel)
                        .accessibilityIdentifier("connection.toField")
                }
                Section(String(localized: "Note (optional)")) {
                    TextField(String(localized: "Note"), text: $note, axis: .vertical)
                }
                if let errorMessage {
                    Text(errorMessage).foregroundStyle(RTColors.danger)
                }
            }
            .navigationTitle("Add Connection")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Save")) { save() }
                        .accessibilityIdentifier("connection.saveButton")
                }
            }
        }
    }

    private func save() {
        let service = container.mutationService(context: modelContext)
        do {
            _ = try service.addConnection(
                to: project,
                stepID: linkedStepID,
                fromLabel: fromLabel,
                toLabel: toLabel,
                note: note.isEmpty ? nil : note
            )
            dismiss()
        } catch {
            errorMessage = String(localized: "Enter both a \"from\" and \"to\" label.")
        }
    }
}
