import Foundation
import SwiftUI
import Observation

enum RTColorSchemePreference: String, Codable, Sendable, CaseIterable {
    case system
    case light
    case dark

    var displayName: String {
        switch self {
        case .system: return String(localized: "System")
        case .light: return String(localized: "Light")
        case .dark: return String(localized: "Dark")
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

/// UserDefaults-backed app preferences. A thin, testable wrapper so views
/// never talk to `UserDefaults` directly.
@MainActor
@Observable
final class AppSettingsStore {
    private let defaults: UserDefaults

    // Stored properties (not computed get/set over UserDefaults) so
    // @Observable can actually track mutations and re-render dependent
    // views — a computed property's setter is invisible to Observation.
    var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: Keys.onboarding) }
    }

    var colorSchemePreference: RTColorSchemePreference {
        didSet { defaults.set(colorSchemePreference.rawValue, forKey: Keys.colorScheme) }
    }

    var imageQuality: RTImageQuality {
        didSet { defaults.set(imageQuality.rawValue, forKey: Keys.imageQuality) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        hasCompletedOnboarding = defaults.bool(forKey: Keys.onboarding)
        colorSchemePreference = RTColorSchemePreference(rawValue: defaults.string(forKey: Keys.colorScheme) ?? "") ?? .system
        imageQuality = RTImageQuality(rawValue: defaults.string(forKey: Keys.imageQuality) ?? "") ?? .standard
    }

    private enum Keys {
        static let onboarding = "hasCompletedOnboarding"
        static let colorScheme = "colorSchemePreference"
        static let imageQuality = "imageQuality"
    }
}
