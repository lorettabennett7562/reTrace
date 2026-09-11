import Foundation

enum RTProjectStatus: String, Codable, Sendable, CaseIterable {
    case draft
    case capturing
    case disassembled
    case restoring
    case completed
    case archived

    static func from(rawValue: String) -> RTProjectStatus {
        RTProjectStatus(rawValue: rawValue) ?? .draft
    }

    /// Valid forward transitions. A `completed` project can only move to
    /// `archived`, never silently back into an editable state.
    func canTransition(to next: RTProjectStatus) -> Bool {
        switch (self, next) {
        case (.draft, .capturing),
             (.capturing, .capturing),
             (.capturing, .disassembled),
             (.disassembled, .restoring),
             (.disassembled, .archived),
             (.restoring, .restoring),
             (.restoring, .completed),
             (.completed, .archived):
            return true
        default:
            return self == next
        }
    }

    var displayName: String {
        switch self {
        case .draft: return String(localized: "Draft")
        case .capturing: return String(localized: "Active")
        case .disassembled: return String(localized: "Ready to Restore")
        case .restoring: return String(localized: "Restoring")
        case .completed: return String(localized: "Completed")
        case .archived: return String(localized: "Archived")
        }
    }
}

enum RTProjectCategory: String, Codable, Sendable, CaseIterable, Identifiable {
    case electronics
    case computer
    case furniture
    case vehicle
    case bicycle
    case appliance
    case packing
    case home
    case other

    var id: String { rawValue }

    static func from(rawValue: String) -> RTProjectCategory {
        RTProjectCategory(rawValue: rawValue) ?? .other
    }

    var displayName: String {
        switch self {
        case .electronics: return String(localized: "Electronics")
        case .computer: return String(localized: "Computer")
        case .furniture: return String(localized: "Furniture")
        case .vehicle: return String(localized: "Vehicle")
        case .bicycle: return String(localized: "Bicycle")
        case .appliance: return String(localized: "Appliance")
        case .packing: return String(localized: "Packing")
        case .home: return String(localized: "Home")
        case .other: return String(localized: "Other")
        }
    }

    var symbolName: String {
        switch self {
        case .electronics: return "tv"
        case .computer: return "desktopcomputer"
        case .furniture: return "chair"
        case .vehicle: return "car"
        case .bicycle: return "bicycle"
        case .appliance: return "washer"
        case .packing: return "shippingbox"
        case .home: return "house"
        case .other: return "square.grid.2x2"
        }
    }
}

enum RTStepType: String, Codable, Sendable, CaseIterable, Identifiable {
    case reference
    case remove
    case disconnect
    case unplug
    case unscrew
    case part
    case note
    case photo
    case custom

    var id: String { rawValue }

    static func from(rawValue: String) -> RTStepType {
        RTStepType(rawValue: rawValue) ?? .custom
    }

    var displayName: String {
        switch self {
        case .reference: return String(localized: "Reference Only")
        case .remove: return String(localized: "Removed")
        case .disconnect: return String(localized: "Disconnected")
        case .unplug: return String(localized: "Unplugged")
        case .unscrew: return String(localized: "Unscrewed")
        case .part: return String(localized: "Part")
        case .note: return String(localized: "Note")
        case .photo: return String(localized: "Photo")
        case .custom: return String(localized: "Other")
        }
    }

    var symbolName: String {
        switch self {
        case .reference: return "photo"
        case .remove: return "minus.circle"
        case .disconnect: return "cable.connector"
        case .unplug: return "powerplug"
        case .unscrew: return "screwdriver"
        case .part: return "shippingbox"
        case .note: return "note.text"
        case .photo: return "camera"
        case .custom: return "ellipsis.circle"
        }
    }

    /// The verb shown when Restore Mode asks the user to reverse this step.
    var restoreVerb: String {
        switch self {
        case .reference: return String(localized: "Compare with")
        case .remove: return String(localized: "Reattach")
        case .disconnect: return String(localized: "Reconnect")
        case .unplug: return String(localized: "Plug back in")
        case .unscrew: return String(localized: "Rescrew")
        case .part: return String(localized: "Place back")
        case .note: return String(localized: "Review")
        case .photo: return String(localized: "Match")
        case .custom: return String(localized: "Reverse")
        }
    }
}
