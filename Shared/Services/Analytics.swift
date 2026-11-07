import Foundation
@preconcurrency import PostHog
import SwiftUI

/// Product analytics through PostHog (project "Mahj Trainer"). The only file
/// that imports the SDK. Details in `.claude/rules/analytics.md`.
///
/// Never starts on a simulator or in a test run, so calls are no-ops there.
/// A DEBUG run with `-phprobe` opts in to prove the pipeline.
enum Analytics {
    /// Write-only project token, safe in a public repo: it can send events
    /// and cannot read anything.
    private static let projectToken = "phc_t4NfS4bw3YFmYwq4Un7drvkSDDFB7PWXbQvDieeNLLp3"
    private static let host = "https://us.i.posthog.com"

    private static var shouldRun: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.arguments.contains("-phprobe")
        #elseif targetEnvironment(simulator)
        return false
        #else
        return true
        #endif
    }

    static func start() {
        guard shouldRun else { return }
        let config = PostHogConfig(projectToken: projectToken, host: host)
        // Hosting controllers would report meaningless names, and each one
        // would overwrite `$screen_name`. `analyticsScreen` names every screen.
        config.captureScreenViews = false
        // Both off. SwiftUI capture sent almost nothing in testing and walks the
        // accessibility tree on every touch, a risk to the swipe deck. UIKit
        // capture reads a text view's contents, and the feedback box is the
        // one place a player types. Choices get named events instead.
        config.captureSwiftUIElementInteractions = false
        config.captureElementInteractions = false
        config.errorTrackingConfig.autoCapture = true
        // Screen recording needs consent and an indicator (App Review 2.5.14).
        config.sessionReplay = false
        // Remote variants come only through RevenueCat (`RemoteConfig`).
        config.preloadFeatureFlags = false
        config.surveys = false
        // Reminders are local notifications, captured in `AppDelegate`. Off so
        // the SDK leaves the notification delegate alone.
        config.capturePushNotificationSubscriptions = false
        config.capturePushNotificationOpened = false
        PostHogSDK.shared.setup(config)
        // Players who onboarded before this version never pick a level again.
        if let level = UserDefaults.standard.string(forKey: "mahj.skillLevel"), !level.isEmpty {
            register(["skill_level": level])
        }
        if let installed = ConversionDiagnostics.installDate {
            register(["days_since_install": Calendar.current.dateComponents([.day], from: installed, to: .now).day ?? 0])
        }
    }

    static func identify(_ userID: String) {
        PostHogSDK.shared.identify(userID)
    }

    static func capture(_ event: String, _ properties: [String: Any] = [:]) {
        PostHogSDK.shared.capture(event, properties: properties)
    }

    static func screen(_ name: String, _ properties: [String: Any] = [:]) {
        PostHogSDK.shared.screen(name, properties: properties)
    }

    /// Stamped on every later event, so any event can be split by these.
    static func register(_ properties: [String: Any]) {
        PostHogSDK.shared.register(properties)
    }

    static func setPersonProperties(_ properties: [String: Any]) {
        PostHogSDK.shared.setPersonProperties(userPropertiesToSet: properties)
    }

    static func setSharing(_ isOn: Bool) {
        if isOn {
            PostHogSDK.shared.optIn()
        } else {
            PostHogSDK.shared.optOut()
        }
    }
}

extension View {
    /// Reports the screen each time it comes on screen, including when a
    /// pushed screen or sheet above it goes away.
    func analyticsScreen(_ name: String, _ properties: [String: String] = [:]) -> some View {
        onAppear { Analytics.screen(name, properties) }
    }
}
