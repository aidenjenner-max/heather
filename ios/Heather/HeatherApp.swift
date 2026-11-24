import SwiftUI
import WebKit

/// Heather: gentle daily brain games.
/// The games are the same web app as heather-delta.vercel.app, bundled inside the app
/// (so they work offline) and shown in a WKWebView, with native extras: daily reminders,
/// haptics, the iOS share sheet and invite links that open straight into the app.
@main
struct HeatherApp: App {
    @StateObject private var model = WebModel()

    var body: some Scene {
        WindowGroup {
            HeatherWebView(model: model)
                .ignoresSafeArea()
                .background(Color(model.isDark ? "LaunchBackground" : "AppBackground").ignoresSafeArea())
                .preferredColorScheme(model.isDark ? .dark : .light)
                // Invite links (https://heather-delta.vercel.app/?join=CODE) arrive here as universal links.
                .onOpenURL { model.open(link: $0) }
        }
    }
}

struct HeatherWebView: UIViewRepresentable {
    @ObservedObject var model: WebModel
    func makeUIView(context: Context) -> WKWebView { model.webView }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
