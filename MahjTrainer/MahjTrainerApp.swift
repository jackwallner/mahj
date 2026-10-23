import SwiftUI

@main
struct MahjTrainerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var subscriptions = SubscriptionService.shared
    @StateObject private var progress = ProgressStore.shared
    @StateObject private var settings = AppSettings.shared
    @StateObject private var router = AppRouter.shared
    @Environment(\.scenePhase) private var scenePhase

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
                    TrialOfferPacer.noteForeground()
                    Task { await FeedbackService.shared.flushPending() }
                    // Keeps "1st of each month" true for players who never
                    // cold-launch: the three scheduled months roll forward.
                    MonthlyChallengeReminder.refresh()
                    MetaAds.activateApp()
                }
                .onAppear {
                    #if DEBUG
                    DebugShot.seedIfRequested()
                    #endif
                    // Before anything reads mastery: pre-1.1 installs carry
                    // their whole history in ProgressStore's flat sets, and
                    // Home, Room and Stats have to tell one story about it.
                    PracticeRecordStore.shared.migrateLegacyProgress(
                        seen: progress.seenItems,
                        missed: progress.missedItems
                    )
                    subscriptions.start()
                    MonthlyChallengeReminder.refresh()
                    ReviewPromptTracker.recordAppLaunch()
                    ConversionDiagnostics.recordAppOpen()
                    TrialOfferPacer.noteForeground()
                    Task { await FeedbackService.shared.flushPending() }
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
