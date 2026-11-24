import SwiftUI
import WebKit

/// Owns the web view that runs the bundled Heather web app.
@MainActor
final class WebModel: NSObject, ObservableObject {
    static let scheme = "heather"
    static let home = URL(string: "heather://app/index.html")!
    /// The public website. Links to pages like Privacy and Help open there, in Safari.
    static let website = URL(string: "https://heather-delta.vercel.app/")!

    let webView: WKWebView
    @Published var isDark = true   // the loading screen is dark; the page tells us when that changes
    private let bridge = NativeBridge()

    override init() {
        let config = WKWebViewConfiguration()
        config.setURLSchemeHandler(BundleSchemeHandler(), forURLScheme: Self.scheme)
        config.websiteDataStore = .default()          // keeps the garden (localStorage) between launches
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.dataDetectorTypes = []

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let content = WKUserContentController()
        content.addUserScript(WKUserScript(
            source: "window.HEATHER_NATIVE = { platform: 'ios', version: '\(version)' };",
            injectionTime: .atDocumentStart, forMainFrameOnly: true))
        config.userContentController = content

        webView = WKWebView(frame: .zero, configuration: config)
        super.init()

        content.add(WeakMessageHandler(self), name: "heather")
        bridge.webView = webView
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.isOpaque = false
        webView.backgroundColor = UIColor(named: "LaunchBackground")
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.contentInsetAdjustmentBehavior = .never   // the page handles safe areas itself
        webView.allowsBackForwardNavigationGestures = false
        webView.allowsLinkPreview = false
        #if DEBUG
        if #available(iOS 16.4, *) { webView.isInspectable = true }   // Safari > Develop menu while testing
        #endif
        webView.load(URLRequest(url: Self.home))
    }

    /// Open an invite link inside the app: keeps ?join= and ?from= and reloads the game page.
    func open(link: URL) {
        guard let parts = URLComponents(url: link, resolvingAgainstBaseURL: false) else { return }
        var target = URLComponents(url: Self.home, resolvingAgainstBaseURL: false)!
        let keep = (parts.queryItems ?? []).filter { ["join", "from"].contains($0.name) }
        target.queryItems = keep.isEmpty ? nil : keep
        if let url = target.url { webView.load(URLRequest(url: url)) }
    }

    /// The game page itself (with or without ?join=) stays in the app; everything else opens outside.
    private func isAppPage(_ url: URL) -> Bool {
        guard url.scheme == Self.scheme else { return false }
        let name = (url.path as NSString).lastPathComponent
        return name.isEmpty || name == "/" || name == "index.html"
    }

    /// Text messages, email, Facebook and website pages (Privacy, Help) open outside the app.
    private func openOutside(_ url: URL) {
        var url = url
        if url.scheme == Self.scheme {               // e.g. heather://app/privacy -> the website's Privacy page
            let page = String(url.path.drop(while: { $0 == "/" }))
            url = URL(string: page, relativeTo: Self.website)?.absoluteURL ?? Self.website
        }
        UIApplication.shared.open(url)
    }
}

extension WebModel: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        guard let url = navigationAction.request.url else { return .cancel }
        if isAppPage(url) || url.scheme == "about" { return .allow }
        openOutside(url)
        return .cancel
    }

    /// If iOS ever unloads the page in the background, bring it straight back.
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) { webView.reload() }
}

extension WebModel: WKUIDelegate {
    /// Links with target="_blank" (Facebook share, Privacy, Help) open outside the app.
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = navigationAction.request.url { openOutside(url) }
        return nil
    }
}

extension WebModel: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any], let type = body["type"] as? String else { return }
        if type == "theme" {
            isDark = body["dark"] as? Bool ?? false
        } else {
            bridge.handle(type: type, body: body)
        }
    }
}

/// Stops the message handler from keeping the model alive forever.
@MainActor
final class WeakMessageHandler: NSObject, WKScriptMessageHandler {
    weak var target: WKScriptMessageHandler?
    init(_ target: WKScriptMessageHandler) { self.target = target }
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        target?.userContentController(userContentController, didReceive: message)
    }
}
