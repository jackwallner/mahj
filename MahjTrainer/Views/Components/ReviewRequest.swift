import StoreKit
import SwiftUI

extension View {
    /// Calls Apple's rating prompt a few seconds after a positive moment,
    /// with no question in front of it. Bump `moment` when the moment
    /// happens (a finished drill, a finished challenge).
    ///
    /// `isClear` is checked again when the wait is over, so the prompt never
    /// lands on a sheet the player opened in the meantime; the view leaving
    /// the screen cancels it too.
    func requestsReview(after moment: Int, isClear: @escaping () -> Bool = { true }) -> some View {
        modifier(ReviewRequestModifier(moment: moment, isClear: isClear))
    }
}

private struct ReviewRequestModifier: ViewModifier {
    let moment: Int
    let isClear: () -> Bool

    @Environment(\.requestReview) private var requestReview
    @State private var onScreen = false

    func body(content: Content) -> some View {
        content
            .onAppear { onScreen = true }
            .onDisappear { onScreen = false }
            .onChange(of: moment) { _, _ in schedule() }
    }

    private func schedule() {
        // RevenueCat's `rating_prompt: off` pauses the asks without a release.
        guard SubscriptionService.shared.isOn(.ratingPrompt), ReviewPromptTracker.shouldRequestReview() else { return }
        Task { @MainActor in
            // Let the celebration land first.
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard onScreen, isClear(), SubscriptionService.shared.isOn(.ratingPrompt),
                  ReviewPromptTracker.shouldRequestReview() else { return }
            ReviewPromptTracker.markShown()
            requestReview()
        }
    }
}
