import SwiftUI

struct DrillCompleteView: View {
    let drill: Drill
    let score: Int?
    let total: Int
    /// Supplied when there is no navigation stack to pop (the onboarding
    /// tour's cover); otherwise Done just dismisses.
    var onDone: (() -> Void)?

    @EnvironmentObject private var progress: ProgressStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var recorded = false
    /// Bumped once when the drill is banked: the rating prompt's cue.
    @State private var reviewMoment = 0
    @State private var celebrate = false
    @State private var confettiTrigger = 0
    @State private var showPaywall = false

    var body: some View {
        VStack(spacing: 16) {
            // Scrolls when it has to: at the largest text sizes the message
            // used to truncate in a fixed stack.
            CenteringScrollView {
                VStack(spacing: 22) {
                    summary
                    MahjPlusPitchCard { showPaywall = true }
                        .frame(maxWidth: 520)
                }
            }
            Button {
                if let onDone { onDone() } else { dismiss() }
            } label: {
                Text("Done").primaryCTA()
            }
        }
        .padding()
        .background(Theme.background)
        .overlay { ConfettiBurst(trigger: confettiTrigger, origin: .init(x: 0.5, y: 0.3), particleCount: 44) }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            celebrate = true
            confettiTrigger += 1
            guard !recorded else { return }
            recorded = true
            Haptics.success()
            SoundPlayer.play(.complete)
            progress.recordSession(drillID: drill.id)
            // The ask is for a good moment: half right or better (a deck has
            // no score and always counts).
            if score.map({ Double($0) / Double(max(total, 1)) >= 0.5 }) ?? true {
                reviewMoment += 1
            }
        }
        // One ask per moment: the trial sheet, when it is due, goes first and
        // the rating prompt stands down for that result.
        .trialOffer(.drillResult, isPresented: $showPaywall, autoMoment: reviewMoment)
        .requestsReview(after: reviewMoment, isClear: { !showPaywall && !TrialOfferPacer.autoShownRecently() })
    }

    private var summary: some View {
        VStack(spacing: 22) {
            ZStack {
                Circle()
                    .fill(Theme.jade.opacity(0.12))
                    .frame(width: 132, height: 132)
                    .scaleEffect(celebrate ? 1 : 0.6)
                if let score {
                    VStack(spacing: 2) {
                        Text("\(score)/\(total)")
                            .font(Theme.display(34))
                            .foregroundStyle(Theme.jade)
                            .monospacedDigit()
                        Text("right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.inkSecondary)
                    }
                } else {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 58))
                        .foregroundStyle(Theme.jade)
                }
            }
            .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.6), value: celebrate)
            VStack(spacing: 8) {
                Text(headline)
                    .font(Theme.display(30))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Text(subheadline)
                    .font(.body)
                    .foregroundStyle(Theme.inkSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(Theme.coral)
                Text("\(progress.currentStreak())-day streak")
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .themedCard(corner: 22)
        }
        .padding(.vertical, 8)
    }

    private var headline: String {
        guard let score else { return "Deck cleared!" }
        let fraction = Double(score) / Double(max(total, 1))
        if fraction >= 1 { return "Perfect round!" }
        if fraction >= 0.7 { return "Nice work!" }
        return "Good practice!"
    }

    private var subheadline: String {
        if score == nil {
            return "All \(total) cards down. They'll stick a little better every pass."
        }
        switch drill.kind {
        case .charleston: return "Every pass you pick here is one you'll make faster at the table."
        case .handMatch: return "Every rack you read here is one you'll read faster at the table."
        case .quiz, .flashcards: return "Every call you make here is one you'll make faster at the table."
        }
    }
}
