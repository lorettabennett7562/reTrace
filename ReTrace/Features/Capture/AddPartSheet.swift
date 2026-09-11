import SwiftData
import SwiftUI

struct AddPartSheet: View {
    let project: RTProject
    let linkedStep: RTStep?

    @Environment(AppContainer.self) private var container
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var quantity = 1
    @State private var storageLabel = ""
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "Part")) {
                    TextField(String(localized: "Name"), text: $name)
                        .accessibilityIdentifier("part.nameField")
                    Stepper(value: $quantity, in: 0...999) {
                        Text("Quantity: \(quantity)")
                    }
                    .accessibilityIdentifier("part.quantityStepper")
                }

                Section(String(localized: "Storage")) {
                    TextField(String(localized: "e.g. Bag A"), text: $storageLabel)
                        .accessibilityIdentifier("part.storageField")
                }

                Section(String(localized: "Note (optional)")) {
                    TextField(String(localized: "Note"), text: $note, axis: .vertical)
                }
            }
            .navigationTitle("Add Part")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Save")) { save() }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .accessibilityIdentifier("part.saveButton")
                }
            }
        }
    }

    private func save() {
        let service = container.mutationService(context: modelContext)
        service.addPart(
            to: project,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            quantity: quantity,
            storageLabel: storageLabel.isEmpty ? nil : storageLabel,
            note: note.isEmpty ? nil : note,
            linkedStep: linkedStep
        )
        dismiss()
    }
}
