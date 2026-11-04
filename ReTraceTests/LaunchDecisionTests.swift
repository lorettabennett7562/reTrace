import XCTest
@testable import ReTrace

@MainActor
final class LaunchDecisionTests: XCTestCase {
    func testLaunchContractPersistenceAndNaming() throws {
        let native = try JSONDecoder().decode(LaunchDecision.self, from: Data(#"{"retraceFlow":"questLog"}"#.utf8)).validated()
        XCTAssertEqual(native.flow, .native)
        let nativeJSON = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(native)) as? [String: String])
        XCTAssertEqual(nativeJSON, ["retraceFlow": "questLog"])
        XCTAssertNil(nativeJSON["url"])
        let web = try JSONDecoder().decode(LaunchDecision.self, from: Data(#"{"retraceFlow":"retraceHub","url":"https://example.com/start"}"#.utf8)).validated()
        XCTAssertEqual(web.flow, .web)
        let encoded = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(web)) as? [String: String])
        XCTAssertEqual(encoded["retraceFlow"], "retraceHub")
        XCTAssertNil(encoded["flow"])
        XCTAssertThrowsError(try LaunchDecision(flow: .web, url: nil).validated())
        XCTAssertThrowsError(try LaunchDecision(flow: .web, url: URL(string: "file:///etc/passwd")).validated())
        XCTAssertThrowsError(try JSONDecoder().decode(LaunchDecision.self, from: Data(#"{"retraceFlow":"unknown"}"#.utf8)))

        let suite = "LaunchDecisionTests.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = LaunchDecisionStore(defaults: defaults)
        XCTAssertNil(store.decision)
        try store.save(web)
        XCTAssertEqual(LaunchDecisionStore(defaults: defaults).decision, web)
        XCTAssertThrowsError(try store.save(LaunchDecision(flow: .web, url: nil)))
        XCTAssertEqual(LaunchDecisionStore(defaults: defaults).decision, web)
        try store.save(native)
        XCTAssertEqual(LaunchDecisionStore(defaults: defaults).decision, native)

        let configured = try JSONDecoder().decode(LaunchDecision.self, from: Data(#"{"retraceFlow":"questLog","projectTemplates":[{"title":"PC Upgrade","category":"computer"}]}"#.utf8)).validated()
        XCTAssertEqual(configured.projectTemplates?.first?.category, .computer)
        try store.save(configured)
        XCTAssertEqual(LaunchDecisionStore(defaults: defaults).decision, configured)
        var invalid = configured
        invalid.projectTemplates = [.init(title: "  ", category: .other)]
        XCTAssertThrowsError(try invalid.validated())
        invalid.projectTemplates = Array(repeating: .init(title: "Duplicate", category: .other), count: 2)
        XCTAssertThrowsError(try invalid.validated())
        invalid.projectTemplates = (0..<9).map { .init(title: "Project \($0)", category: .other) }
        XCTAssertThrowsError(try invalid.validated())

        let adjust = AdjustService()
        adjust.processDeepLink(try XCTUnwrap(URL(string: "retrace://open?adj_campaign=Full%20Campaign&adj_adgroup=Group&adj_creative=Creative&adj_label=Label")))
        adjust.processDeepLink(try XCTUnwrap(URL(string: "retrace://open?adj_t=token")))
        XCTAssertEqual(adjust.naming["campaign"], "Full Campaign")
        XCTAssertEqual(adjust.naming["adgroup"], "Group")
        XCTAssertEqual(adjust.naming["creative"], "Creative")
        XCTAssertEqual(adjust.naming["clickLabel"], "Label")
        XCTAssertEqual(adjust.naming["trackerToken"], "token")
        XCTAssertNil(adjust.naming["adid"])
        let request = LaunchRequest(appid: "com.retrace.lorettapp", idfv: nil, pushToken: "", userAgent: "test", oneLink: "", appsAttr: "{}", adjustAdid: "adjust-id")
        let requestJSON = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(request)) as? [String: Any])
        XCTAssertNil(requestJSON["idfa"])
        XCTAssertNil(requestJSON["deviceName"])
        XCTAssertEqual(requestJSON["pushToken"] as? String, "")
        XCTAssertEqual(requestJSON["adjustAdid"] as? String, "adjust-id")
        let manifestURL = try XCTUnwrap(Bundle.main.url(forResource: "PrivacyInfo", withExtension: "xcprivacy"))
        let manifest = try XCTUnwrap(PropertyListSerialization.propertyList(from: Data(contentsOf: manifestURL), format: nil) as? [String: Any])
        XCTAssertEqual(manifest["NSPrivacyTracking"] as? Bool, false)
        XCTAssertEqual(manifest["NSPrivacyTrackingDomains"] as? [String], [])
    }
}
