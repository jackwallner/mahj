import Foundation
import UserNotifications

/// Notification mutations make synchronous XPC calls even when their API
/// returns Void. Keep them off the UI thread, and keep remove/add ordering.
enum NotificationRequests {
    struct Request: Sendable {
        let identifier: String
        let title: String
        let body: String
        let components: DateComponents
        let repeats: Bool
        var userInfo: [String: String] = [:]
    }

    private static let queue = DispatchQueue(
        label: "com.jackwallner.mahj.notification-requests", qos: .utility
    )

    static func perform(_ update: @escaping @Sendable () -> Void) {
        queue.async(execute: update)
    }

    static func remove(_ identifiers: [String]) {
        replace([], removing: identifiers)
    }

    static func replace(_ requests: [Request], removing identifiers: [String]) {
        perform {
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: identifiers)
            for request in requests {
                let content = UNMutableNotificationContent()
                content.title = request.title
                content.body = request.body
                content.sound = .default
                content.userInfo = request.userInfo
                let trigger = UNCalendarNotificationTrigger(dateMatching: request.components, repeats: request.repeats)
                center.add(UNNotificationRequest(identifier: request.identifier, content: content, trigger: trigger))
            }
        }
    }
}
