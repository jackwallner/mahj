import SwiftUI
import UIKit
import UserNotifications

enum AppDestination: Hashable {
    case gameNightPrepSession
    case monthlyChallenge

    /// Free destinations open for everyone; the rest wait behind the paywall.
    var isFree: Bool { self == .monthlyChallenge }

    /// `mahj://challenge` is what each month's App Store in-app event opens.
    init?(url: URL) {
        guard url.scheme == "mahj" else { return nil }
        switch url.host {
        case "challenge": self = .monthlyChallenge
        default: return nil
        }
    }
}

enum AppNotification {
    static let routeKey = "mahj.route"
    static let gameNightPrepValue = "game-night-prep"
    static let monthlyChallengeValue = "monthly-challenge"
}

@MainActor
final class AppRouter: ObservableObject {
    static let shared = AppRouter()

    @Published private(set) var pendingDestination: AppDestination?

    func route(to destination: AppDestination) {
        pendingDestination = destination
    }

    func consumePendingDestination() -> AppDestination? {
        defer { pendingDestination = nil }
        return pendingDestination
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        switch response.notification.request.content.userInfo[AppNotification.routeKey] as? String {
        case AppNotification.gameNightPrepValue:
            Task { @MainActor in AppRouter.shared.route(to: .gameNightPrepSession) }
        case AppNotification.monthlyChallengeValue:
            Task { @MainActor in AppRouter.shared.route(to: .monthlyChallenge) }
        default:
            break
        }
        completionHandler()
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
