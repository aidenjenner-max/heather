import Foundation
import UniformTypeIdentifiers
import WebKit

/// Serves the web app's files (index.html, words.json, …) from inside the app bundle
/// at heather://app/… so the games load instantly and work without internet.
@MainActor
final class BundleSchemeHandler: NSObject, WKURLSchemeHandler {
    func webView(_ webView: WKWebView, start task: WKURLSchemeTask) {
        guard let url = task.request.url else { return }
        var name = (url.path as NSString).lastPathComponent
        if name.isEmpty || name == "/" || name == "app" { name = "index.html" }

        guard let file = Self.find(name) ?? Self.find(name + ".html"),
              let data = try? Data(contentsOf: file) else {
            task.didFailWithError(URLError(.fileDoesNotExist))
            return
        }
        let mime = UTType(filenameExtension: file.pathExtension)?.preferredMIMEType ?? "application/octet-stream"
        let headers = [
            "Content-Type": mime.hasPrefix("text/") || mime.hasSuffix("json") ? "\(mime); charset=utf-8" : mime,
            "Content-Length": String(data.count),
            "Cache-Control": "no-cache"
        ]
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers)!
        task.didReceive(response)
        task.didReceive(data)
        task.didFinish()
    }

    func webView(_ webView: WKWebView, stop task: WKURLSchemeTask) {}

    /// Xcode may copy the Web folder's files to the top of the app or keep the folder; look in both.
    private static func find(_ name: String) -> URL? {
        guard let root = Bundle.main.resourceURL else { return nil }
        for candidate in [root.appendingPathComponent(name), root.appendingPathComponent("Web").appendingPathComponent(name)]
        where FileManager.default.fileExists(atPath: candidate.path) {
            return candidate
        }
        return nil
    }
}
