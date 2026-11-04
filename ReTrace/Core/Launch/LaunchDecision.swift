import Foundation
import Observation
import UIKit
import WebKit

enum LaunchFlow: String, Codable {
    case native = "questLog"
    case web = "retraceHub"
}

struct ProjectTemplate: Codable, Hashable {
    let title: String
    let category: RTProjectCategory

    static let defaults: [Self] = [
        .init(title: "TV Setup", category: .electronics),
        .init(title: "PC Upgrade", category: .computer),
        .init(title: "Desk Disassembly", category: .furniture),
        .init(title: "Pack Console", category: .packing),
        .init(title: "Bike Repair", category: .bicycle)
    ]
}

struct LaunchDecision: Codable, Equatable {
    let flow: LaunchFlow
    let url: URL?
    var projectTemplates: [ProjectTemplate]? = nil

    enum CodingKeys: String, CodingKey {
        case flow = "retraceFlow"
        case url, projectTemplates
    }

    func validated() throws -> Self {
        if flow == .native, let projectTemplates {
            guard !projectTemplates.isEmpty, projectTemplates.count <= 8,
                  Set(projectTemplates.map(\.title)).count == projectTemplates.count,
                  projectTemplates.allSatisfy({
                      !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && $0.title.count <= 80
                  }) else { throw URLError(.badServerResponse) }
        }
        if flow == .web {
            guard let url, url.scheme?.lowercased() == "https", url.host != nil,
                  url.user == nil, url.password == nil else { throw URLError(.badServerResponse) }
        }
        return self
    }
}

@MainActor
@Observable
final class LaunchDecisionStore {
    private let defaults: UserDefaults
    private(set) var decision: LaunchDecision?
    private let key = "launch.decision"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: key),
           let value = try? JSONDecoder().decode(LaunchDecision.self, from: data) {
            decision = try? value.validated()
        }
    }

    func save(_ value: LaunchDecision) throws {
        let validated = try value.validated()
        defaults.set(try JSONEncoder().encode(validated), forKey: key)
        decision = validated
    }
}

struct LaunchRequest: Encodable {
    let appid: String
    let idfv: String?
    let pushToken: String
    let userAgent: String
    let oneLink: String
    let appsAttr: String
    let adjustAdid: String
}

@MainActor
struct RemoteLaunchClient {
    var endpoint = URL(string: "https://rtrace.xyz/retraceuser")!
    var session = URLSession.shared

    func fetchDecision() async throws -> LaunchDecision {
        let adjust = AdjustService.shared
        async let userAgent = webUserAgent()
        try await adjust.waitForAttribution()
        let payload = LaunchRequest(
            appid: Bundle.main.bundleIdentifier ?? "", idfv: UIDevice.current.identifierForVendor?.uuidString,
            pushToken: "", userAgent: await userAgent,
            oneLink: adjust.oneLink, appsAttr: adjust.appsAttr, adjustAdid: adjust.adjustAdid
        )
        var request = URLRequest(url: endpoint, timeoutInterval: 30)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(payload)
        let (data, response) = try await session.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        return try JSONDecoder().decode(LaunchDecision.self, from: data).validated()
    }

    private func webUserAgent() async -> String {
        let webView = WKWebView()
        return await withCheckedContinuation { continuation in
            webView.evaluateJavaScript("navigator.userAgent") { [webView] value, _ in
                _ = webView // Keep the view alive until its callback completes.
                continuation.resume(returning: value as? String ?? "")
            }
        }
    }
}
