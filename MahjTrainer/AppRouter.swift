import SwiftUI
import UIKit
import UserNotifications

enum AppDestination: Hashable {
    case quickSession
    case ordinaryRun
    case gameNightPrepSession
    case monthlyChallenge
    case endlessPicker
    case gameNightPrep
    case timedChallenge
    case review
    case handPlay
    #if DEBUG
    /// Screenshot-only route (`mahj://shot/<name>`), see `DebugShot`.
    case debugShot(String)
    #endif

    /// Free destinations open for everyone; the rest wait behind the paywall.
    var isFree: Bool {
        #if DEBUG
        if case .debugShot = self { return true }
        #endif
        return self == .monthlyChallenge || self == .quickSession || self == .ordinaryRun
    }

    /// `mahj://challenge` is what each month's App Store in-app event opens.
    init?(url: URL) {
        guard url.scheme == "mahj" else { return nil }
        #if DEBUG
        if url.host == "shot" {
            self = .debugShot(url.pathComponents.dropFirst().joined(separator: "/"))
            return
        }
        #endif
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
        MetaAds.start(application, launchOptions: launchOptions)
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
