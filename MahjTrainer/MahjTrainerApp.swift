import os
import SwiftUI
import UIKit

@main
struct MahjTrainerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var subscriptions = SubscriptionService.shared
    @StateObject private var progress = ProgressStore.shared
    @StateObject private var settings = AppSettings.shared
    @StateObject private var router = AppRouter.shared
    @Environment(\.scenePhase) private var scenePhase

    #if DEBUG
    init() { LaunchTiming.mark("app init") }
    #endif

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(subscriptions)
                .environmentObject(progress)
                .environmentObject(settings)
                .environmentObject(router)
                .preferredColorScheme(settings.appearance.colorScheme)
                .onOpenURL { url in
                    if let destination = AppDestination(url: url) { router.route(to: destination) }
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .background { TrialOfferPacer.noteBackground() }
                    // iOS rarely cold-launches an app, so a report queued
                    // offline also retries every time the app comes back.
                    guard phase == .active else { return }
                    DayClock.shared.refresh()
                    TrialOfferPacer.noteForeground()
                    Task { await FeedbackService.shared.flushPending() }
                    // Keeps "1st of each month" true for players who never
                    // cold-launch: the three scheduled months roll forward.
                    MonthlyChallengeReminder.refresh()
                    MetaAds.activateApp()
                }
                // Midnight with the app open, and clock or time zone changes.
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
                    DayClock.shared.refresh()
                }
                .onAppear {
                    #if DEBUG
                    LaunchTiming.mark("root appear")
                    DispatchQueue.main.async { LaunchTiming.mark("first commit") }
                    DebugShot.seedIfRequested()
                    DebugShot.routeIfRequested(router)
                    #endif
                    // Before anything reads mastery: pre-1.1 installs carry
                    // their whole history in ProgressStore's flat sets, and
                    // Home, Room and Stats have to tell one story about it.
                    PracticeRecordStore.shared.migrateLegacyProgress(
                        seen: progress.seenItems,
                        missed: progress.missedItems
                    )
                    ReviewPromptTracker.recordAppLaunch()
                    ConversionDiagnostics.recordAppOpen()
                    TrialOfferPacer.noteForeground()
                    // After the first frame: none of this draws anything, and
                    // run here it held the launch screen up (release gate,
                    // blank launch).
                    Task { @MainActor in
                        await Task.yield()
                        subscriptions.start()
                        // Today's questions, built off the main thread so
                        // opening the challenge does not wait for them.
                        Task.detached(priority: .utility) { _ = MonthlyChallengeContent.currentRound()?.items }
                        MonthlyChallengeReminder.refresh()
                        await FeedbackService.shared.flushPending()
                    }
                    #if DEBUG
                    if RevenueCatProbe.isEnabled {
                        // Same entry point the real paywall screens call, so
                        // what this proves is the actual path, not a parallel one.
                        subscriptions.trackPaywallImpression(id: RevenueCatProbe.impressionID)
                        if RevenueCatProbe.wantsPurchase {
                            Task {
                                await subscriptions.loadOfferings()
                                let package = subscriptions.offerings?.current?.availablePackages.first
                                NSLog("RCPROBE offerings=%@ current=%@ packages=%d",
                                      String(describing: subscriptions.offerings != nil),
                                      subscriptions.offerings?.current?.identifier ?? "nil",
                                      subscriptions.offerings?.current?.availablePackages.count ?? -1)
                                do {
                                    let outcome = try await subscriptions.purchase(package)
                                    NSLog("RCPROBE purchase outcome=%@", String(describing: outcome))
                                } catch {
                                    NSLog("RCPROBE purchase error=%@", String(describing: error))
                                }
                            }
                        }
                    }
                    #endif
                }
        }
    }
}

#if DEBUG
/// "launch-timing" lines in the device log: milliseconds from process start
/// to the App's init, the first appear and the commit after it, so a blank
/// launch can be split into the app's own work and the simulator's.
enum LaunchTiming {
    static func mark(_ step: String) {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        guard sysctl(&mib, 4, &info, &size, nil, 0) == 0 else { return }
        let start = info.kp_proc.p_starttime
        let started = Double(start.tv_sec) + Double(start.tv_usec) / 1_000_000
        let ms = Int((Date().timeIntervalSince1970 - started) * 1000)
        // A Logger, not NSLog: `log show` can compose a message whose format
        // lives in the app's own image.
        logger.notice("launch-timing \(step, privacy: .public) \(ms, privacy: .public) ms")
    }

    private static let logger = Logger(subsystem: "com.jackwallner.mahj", category: "launch")
}
#endif
