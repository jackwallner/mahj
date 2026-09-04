import SwiftUI

@main
struct MahjTrainerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var subscriptions = SubscriptionService.shared
    @StateObject private var progress = ProgressStore.shared
    @StateObject private var settings = AppSettings.shared
    @StateObject private var router = AppRouter.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(subscriptions)
                .environmentObject(progress)
                .environmentObject(settings)
                .environmentObject(router)
                .preferredColorScheme(settings.appearance.colorScheme)
                .onAppear {
                    subscriptions.start()
                    ReviewPromptTracker.recordAppLaunch()
                    ConversionDiagnostics.recordAppOpen()
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
