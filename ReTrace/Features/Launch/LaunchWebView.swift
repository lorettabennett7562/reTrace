import Combine
import SwiftUI
import UIKit
import WebKit

private struct LaunchWKWebView: UIViewRepresentable {
    let webView: WKWebView

    func makeUIView(context: Context) -> WKWebView { webView }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

@MainActor
final class LaunchWebViewModel: NSObject, ObservableObject, WKNavigationDelegate, WKUIDelegate, WKDownloadDelegate {
    @Published private(set) var canGoBack = false
    @Published private(set) var canGoForward = false
    @Published private(set) var isLoading = false
    @Published private(set) var progress = 0.0
    @Published private(set) var loadFailed = false

    let webView: WKWebView
    private var downloadDestination: URL?
    @Published var externalLinkError: String?
    var openURL: (URL, @escaping (Bool) -> Void) -> Void = { url, completion in
        UIApplication.shared.open(url, options: [:], completionHandler: completion)
    }

    override init() {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        // Keep payment web content free of injected scripts for Apple Pay compatibility.

        webView = WKWebView(frame: .zero, configuration: configuration)
        super.init()
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.allowsLinkPreview = true
        webView.scrollView.contentInsetAdjustmentBehavior = .automatic
    }

    func load(_ url: URL) {
        guard webView.url == nil else { return }
        webView.load(URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30))
    }

    func goBack() { if webView.canGoBack { webView.goBack() } }
    func goForward() { if webView.canGoForward { webView.goForward() } }
    func reload() { webView.reload() }

    func retry(_ url: URL) {
        loadFailed = false
        webView.load(URLRequest(url: webView.url ?? url, cachePolicy: .reloadRevalidatingCacheData, timeoutInterval: 30))
    }

    private func refreshState() {
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
        isLoading = webView.isLoading
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        loadFailed = false
        progress = 0.12
        refreshState()
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        progress = 0.65
        refreshState()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        progress = 1
        refreshState()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        setLoadFailure(for: error)
        refreshState()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        setLoadFailure(for: error)
        refreshState()
    }

    private func setLoadFailure(for error: Error) {
        guard (error as? URLError)?.code != .cancelled else { return }
        loadFailed = true
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url,
              let scheme = url.scheme?.lowercased() else {
            decisionHandler(.cancel)
            return
        }

        if Self.isWebScheme(scheme) {
            if navigationAction.shouldPerformDownload {
                decisionHandler(.download)
            } else if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
            return
        }

        decisionHandler(.cancel)
        openExternalURL(url)
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
    ) {
        decisionHandler(navigationResponse.canShowMIMEType ? .allow : .download)
    }

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        if let url = navigationAction.request.url {
            if Self.isWebScheme(url.scheme?.lowercased() ?? "") {
                webView.load(navigationAction.request)
            } else {
                openExternalURL(url)
            }
        }
        return nil
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping () -> Void
    ) {
        guard let presenter = Self.topViewController() else { completionHandler(); return }
        let alert = UIAlertController(title: webView.title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
        presenter.present(alert, animated: true)
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (Bool) -> Void
    ) {
        guard let presenter = Self.topViewController() else { completionHandler(false); return }
        let alert = UIAlertController(title: webView.title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(false) })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(true) })
        presenter.present(alert, animated: true)
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (String?) -> Void
    ) {
        guard let presenter = Self.topViewController() else { completionHandler(nil); return }
        let alert = UIAlertController(title: webView.title, message: prompt, preferredStyle: .alert)
        alert.addTextField { $0.text = defaultText }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(nil) })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completionHandler(alert.textFields?.first?.text)
        })
        presenter.present(alert, animated: true)
    }

    func webView(
        _ webView: WKWebView,
        requestMediaCapturePermissionFor origin: WKSecurityOrigin,
        initiatedByFrame frame: WKFrameInfo,
        type: WKMediaCaptureType,
        decisionHandler: @escaping (WKPermissionDecision) -> Void
    ) {
        decisionHandler(.prompt)
    }

    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        download.delegate = self
    }

    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        download.delegate = self
    }

    func download(
        _ download: WKDownload,
        decideDestinationUsing response: URLResponse,
        suggestedFilename: String,
        completionHandler: @escaping (URL?) -> Void
    ) {
        let safeName = suggestedFilename.replacingOccurrences(of: "/", with: "-")
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent(safeName)
        try? FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
        downloadDestination = destination
        completionHandler(destination)
    }

    func downloadDidFinish(_ download: WKDownload) {
        guard let destination = downloadDestination,
              let presenter = Self.topViewController() else { return }
        let share = UIActivityViewController(activityItems: [destination], applicationActivities: nil)
        share.popoverPresentationController?.sourceView = presenter.view
        share.popoverPresentationController?.sourceRect = CGRect(
            x: presenter.view.bounds.midX,
            y: presenter.view.bounds.midY,
            width: 1,
            height: 1
        )
        presenter.present(share, animated: true)
    }

    func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        downloadDestination = nil
    }

    static func isWebScheme(_ scheme: String) -> Bool {
        ["http", "https", "about", "blob", "data"].contains(scheme)
    }

    func openExternalURL(_ url: URL) {
        externalLinkError = nil
        openURL(url) { [weak self] opened in
            guard let self, !opened else { return }
            if let fallback = Self.fallbackURL(for: url) {
                self.openURL(fallback) { [weak self] opened in
                    if !opened { self?.externalLinkError = "This link could not be opened on this device." }
                }
            } else {
                self.externalLinkError = "No app is available to open \(url.scheme ?? "this") links. Install or configure the appropriate app and try again."
            }
        }
    }

    static func fallbackURL(for url: URL) -> URL? {
        if url.scheme?.lowercased() == "intent",
           let marker = url.absoluteString.components(separatedBy: "S.browser_fallback_url=").last,
           marker != url.absoluteString,
           let encoded = marker.components(separatedBy: ";").first,
           let decoded = encoded.removingPercentEncoding,
           let fallback = URL(string: decoded),
           ["https", "http"].contains(fallback.scheme?.lowercased() ?? ""),
           fallback.host != nil {
            return fallback
        }
        return nil
    }

    private static func topViewController(from base: UIViewController? = nil) -> UIViewController? {
        let root = base ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?.rootViewController
        if let navigation = root as? UINavigationController { return topViewController(from: navigation.visibleViewController) }
        if let tab = root as? UITabBarController { return topViewController(from: tab.selectedViewController) }
        if let presented = root?.presentedViewController { return topViewController(from: presented) }
        return root
    }
}

struct LaunchWebView: View {
    let url: URL
    @StateObject private var browser = LaunchWebViewModel()

    var body: some View {
        VStack(spacing: 0) {
            if browser.isLoading && browser.progress < 1 {
                ProgressView(value: browser.progress)
                    .progressViewStyle(.linear)
                    .tint(RTColors.accent)
            }

            ZStack {
                LaunchWKWebView(webView: browser.webView)
                    .accessibilityIdentifier("launch.webView")

                if browser.loadFailed {
                    ContentUnavailableView {
                        Label("Unable to Load Page", systemImage: "wifi.exclamationmark")
                    } description: {
                        Text("Check your internet connection and try again.")
                    } actions: {
                        Button("Try Again") { browser.retry(url) }
                            .buttonStyle(.borderedProminent)
                            .accessibilityIdentifier("launch.retryButton")
                    }
                    .padding()
                    .background(RTColors.background)
                    .accessibilityIdentifier("launch.errorState")
                }
            }

            toolbar
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear { browser.load(url) }
        .alert("Unable to Open Link", isPresented: Binding(
            get: { browser.externalLinkError != nil },
            set: { if !$0 { browser.externalLinkError = nil } }
        )) {
            Button("OK", role: .cancel) { browser.externalLinkError = nil }
        } message: {
            Text(browser.externalLinkError ?? "")
        }
    }

    private var toolbar: some View {
        HStack(spacing: 8) {
            Button(action: browser.goBack) {
                Image(systemName: "chevron.left")
                    .frame(width: 44, height: 44)
            }
            .disabled(!browser.canGoBack)
            .opacity(browser.canGoBack ? 1 : 0.35)
            .accessibilityLabel("Previous page")

            Button(action: browser.goForward) {
                Image(systemName: "chevron.right")
                    .frame(width: 44, height: 44)
            }
            .disabled(!browser.canGoForward)
            .opacity(browser.canGoForward ? 1 : 0.35)
            .accessibilityLabel("Next page")

            Spacer()

            Button(action: browser.reload) {
                Image(systemName: "arrow.clockwise")
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Reload")
        }
        .font(.system(size: 22, weight: .bold))
        .foregroundStyle(Color.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .frame(minHeight: 56)
        .background(Color.black)
    }
}
