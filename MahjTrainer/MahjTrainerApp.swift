import SwiftUI

@main
struct MahjTrainerApp: App {
    @StateObject private var subscriptions = SubscriptionService.shared
    @StateObject private var progress = ProgressStore.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(subscriptions)
                .environmentObject(progress)
                .onAppear { subscriptions.start() }
        }
    }
}
