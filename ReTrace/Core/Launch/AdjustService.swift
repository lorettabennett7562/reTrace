import AdjustSdk
import UIKit

/// All callback state is confined to the main actor. IDFA reading is disabled.
@MainActor
final class AdjustService: NSObject {
    static let shared = AdjustService()
    private var started = false
    private(set) var oneLink = ""
    private(set) var naming: [String: String] = [:]
    private(set) var adjustAdid = ""

    var appsAttr: String {
        guard let data = try? JSONEncoder().encode(naming) else { return "{}" }
        return String(decoding: data, as: UTF8.self)
    }

    func start() {
        guard !started, !LaunchEnvironment.isUITesting,
              let token = Bundle.main.object(forInfoDictionaryKey: "AdjustAppToken") as? String,
              !token.isEmpty, !token.contains("$("),
              let config = ADJConfig(appToken: token, environment: ADJEnvironmentProduction) else { return }
        started = true
        config.logLevel = ADJLogLevel.suppress
        config.disableIdfaReading()
        config.delegate = self
        Adjust.initSdk(config)
        Adjust.adid { value in
            Task { @MainActor in self.adjustAdid = value ?? "" }
        }
        Adjust.attribution { value in
            guard let value else { return }
            Task { @MainActor in self.receive(value) }
        }
        if let url = URL(string: oneLink) { processDeepLink(url) }
    }

    func waitForAttribution() async throws {
        start()
        guard started else { return }
        // Wait up to 30 seconds; continue early when campaign and ADID are available.
        for _ in 0..<120 {
            if naming["campaign"]?.isEmpty == false && !adjustAdid.isEmpty { return }
            try await Task.sleep(for: .milliseconds(250))
        }
    }

    func processDeepLink(_ url: URL) {
        oneLink = url.absoluteString
        mergeDeepLink(url)
        guard started, let link = ADJDeeplink(deeplink: url) else { return }
        Adjust.processAndResolve(link) { resolved in
            guard let resolved, let resolvedURL = URL(string: resolved) else { return }
            Task { @MainActor in
                self.oneLink = resolved
                self.mergeDeepLink(resolvedURL)
            }
        }
    }

    private func mergeDeepLink(_ url: URL) {
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        for (key, aliases) in [
            "trackerToken": ["adj_t", "trackerToken"],
            "trackerName": ["adj_tracker", "trackerName"],
            "network": ["adj_network", "network"],
            "campaign": ["adj_campaign", "campaign"],
            "adgroup": ["adj_adgroup", "adgroup"],
            "creative": ["adj_creative", "creative"],
            "clickLabel": ["adj_label", "clickLabel", "label"]
        ] {
            for alias in aliases {
                if let value = items.first(where: { $0.name == alias })?.value, !value.isEmpty {
                    naming[key] = value
                    break
                }
            }
        }
    }

    private func receive(_ value: ADJAttribution) {
        let fields: [String: String?] = [
            "trackerToken": value.trackerToken, "trackerName": value.trackerName,
            "network": value.network, "campaign": value.campaign,
            "adgroup": value.adgroup, "creative": value.creative,
            "clickLabel": value.clickLabel, "costType": value.costType,
            "costAmount": value.costAmount.map { String(describing: $0) },
            "costCurrency": value.costCurrency
        ]
        for (key, field) in fields {
            if let field, !field.isEmpty { naming[key] = field }
        }
    }
}

extension AdjustService: AdjustDelegate {
    nonisolated func adjustAttributionChanged(_ attribution: ADJAttribution?) {
        guard let attribution else { return }
        Task { @MainActor in self.receive(attribution) }
    }

    nonisolated func adjustDeferredDeeplinkReceived(_ deeplink: URL?) -> Bool {
        if let deeplink {
            Task { @MainActor in
                self.oneLink = deeplink.absoluteString
                self.mergeDeepLink(deeplink)
            }
        }
        return false
    }
}
