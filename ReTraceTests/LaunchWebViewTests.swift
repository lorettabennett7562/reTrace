import XCTest
@testable import ReTrace

@MainActor
final class LaunchWebViewTests: XCTestCase {
    func testExternalLinksAndPaymentConfiguration() throws {
        let browser = LaunchWebViewModel()
        XCTAssertTrue(browser.webView.configuration.userContentController.userScripts.isEmpty)
        for scheme in ["http", "https", "about", "blob", "data"] {
            XCTAssertTrue(LaunchWebViewModel.isWebScheme(scheme))
        }
        var opened: [URL] = []
        browser.openURL = { url, completion in
            opened.append(url)
            completion(true)
        }
        for value in ["mailto:test@example.com", "tg://resolve?domain=telegram", "tel:+1234567890", "sms:+1234567890"] {
            let url = try XCTUnwrap(URL(string: value))
            XCTAssertFalse(LaunchWebViewModel.isWebScheme(url.scheme!))
            browser.openExternalURL(url)
            XCTAssertEqual(opened.last, url)
            XCTAssertNil(browser.externalLinkError)
        }
        browser.openURL = { _, completion in completion(false) }
        browser.openExternalURL(try XCTUnwrap(URL(string: "mailto:test@example.com")))
        XCTAssertNotNil(browser.externalLinkError)

        opened = []
        browser.openURL = { url, completion in
            opened.append(url)
            completion(url.scheme == "https")
        }
        browser.openExternalURL(try XCTUnwrap(URL(string: "intent://open#Intent;S.browser_fallback_url=https%3A%2F%2Fexample.com%2F;end")))
        XCTAssertEqual(opened.map(\.scheme), ["intent", "https"])
        XCTAssertNil(browser.externalLinkError)
        XCTAssertNil(LaunchWebViewModel.fallbackURL(for: try XCTUnwrap(URL(string: "intent://open#Intent;S.browser_fallback_url=javascript%3Aalert(1);end"))))
    }
}
