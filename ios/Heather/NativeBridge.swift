import UIKit
import UserNotifications
import WebKit

/// Things the web app asks the phone to do: haptics, the share sheet and a daily reminder.
@MainActor
final class NativeBridge {
    weak var webView: WKWebView?
    private static let reminderID = "heather.daily"

    func handle(type: String, body: [String: Any]) {
        switch type {
        case "haptic":
            haptic(body["kind"] as? String ?? "light")
        case "share":
            share(title: body["title"] as? String ?? "", text: body["text"] as? String ?? "")
        case "reminder":
            let on = body["on"] as? Bool ?? false
            let hour = body["hour"] as? Int ?? 9
            let minute = body["minute"] as? Int ?? 0
            let name = body["name"] as? String ?? ""
            Task { await setReminder(on: on, hour: hour, minute: minute, name: name) }
        default:
            break
        }
    }

    // MARK: Haptics
    private func haptic(_ kind: String) {
        switch kind {
        case "success": UINotificationFeedbackGenerator().notificationOccurred(.success)
        case "error": UINotificationFeedbackGenerator().notificationOccurred(.warning)
        default: UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    // MARK: Share sheet
    private func share(title: String, text: String) {
        guard let top = Self.topViewController() else { return }
        let sheet = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if !title.isEmpty { sheet.setValue(title, forKey: "subject") }
        if let pop = sheet.popoverPresentationController {           // iPad: show from the middle of the screen
            pop.sourceView = top.view
            pop.sourceRect = CGRect(x: top.view.bounds.midX, y: top.view.bounds.midY, width: 1, height: 1)
            pop.permittedArrowDirections = []
        }
        top.present(sheet, animated: true)
    }

    // MARK: Daily reminder (a local notification; nothing is sent to a server)
    private func setReminder(on: Bool, hour: Int, minute: Int, name: String) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.reminderID])
        guard on else { return }
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        guard granted else { return reply(["type": "reminder", "granted": false]) }

        let content = UNMutableNotificationContent()
        content.title = name.isEmpty ? "Good day!" : "Good day, \(name)!"
        content.body = "Bean has today's puzzles ready in your garden."
        content.sound = .default
        var time = DateComponents()
        time.hour = hour
        time.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
        try? await center.add(UNNotificationRequest(identifier: Self.reminderID, content: content, trigger: trigger))
        reply(["type": "reminder", "granted": true])
    }

    private func reply(_ message: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: message),
              let json = String(data: data, encoding: .utf8) else { return }
        webView?.evaluateJavaScript("window.heatherNativeReply && window.heatherNativeReply(\(json))", completionHandler: nil)
    }

    static func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let scene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
        var top = scene?.windows.first { $0.isKeyWindow }?.rootViewController ?? scene?.windows.first?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
}
