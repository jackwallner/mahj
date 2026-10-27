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

/// What Home does with a routed destination right now.
enum PendingRouteAction: Equatable {
    /// The customer record or the offering's switches are still loading.
    case wait
    /// Switched off remotely: the link just opens Home.
    case drop
    case paywall
    case open
}

extension AppDestination {
    /// A member opening a notification cold reads as free until the customer
    /// record loads, and a cold `mahj://challenge` reads the challenge as on
    /// until the offering says otherwise, so both wait for the answer.
    func routeAction(membershipKnown: Bool, isMember: Bool, remoteConfigKnown: Bool, challengeOn: Bool) -> PendingRouteAction {
        if !isFree, !membershipKnown { return .wait }
        if self == .monthlyChallenge {
            guard remoteConfigKnown else { return .wait }
            guard challengeOn else { return .drop }
        }
        return isFree || isMember ? .open : .paywall
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
