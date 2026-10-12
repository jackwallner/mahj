import StoreKit
import SwiftUI

/// The monthly challenge: free for every player, the same twelve questions on
/// every device, one counted run a month. The App Store in-app event for each
/// month opens here through `mahj://challenge`.
struct MonthlyChallengeView: View {
    @StateObject private var store = MonthlyChallengeStore.shared

    private var challenge: MonthlyChallenge { MonthlyChallengeContent.challenge() }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                hero
                if !pastMonths.isEmpty { archive }
            }
            .padding()
            .frame(maxWidth: Theme.readableContentWidth)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.background)
        .navigationTitle("Monthly Challenge")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var pastMonths: [Date] { MonthlyChallengeContent.pastMonths() }

    private var hero: some View {
        let result = store.result(for: challenge)
        return VStack(spacing: 14) {
            Image(systemName: result == nil ? challenge.theme.icon : "checkmark.seal.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(result == nil ? Theme.plum : Theme.jade)
                .frame(width: 68, height: 68)
                .background((result == nil ? Theme.plum : Theme.jade).opacity(0.13), in: Circle())
            VStack(spacing: 5) {
                Text("\(challenge.monthName.uppercased()) CHALLENGE")
                    .font(.caption.weight(.heavy))
                    .kerning(1.4)
                    .foregroundStyle(Theme.plum)
                Text(challenge.theme.title)
                    .font(Theme.display(27))
                    .foregroundStyle(Theme.ink)
                Text(challenge.theme.blurb)
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(MonthlyChallengeContent.questionCount) questions, the same for every player. Your first run is the one that counts.")
                    .font(.caption)
                    .foregroundStyle(Theme.inkTertiary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
            if let result {
                NavigationLink {
                    MonthlyChallengeResultView(result: result)
                } label: {
                    Text("View Your \(result.score)/\(result.total)").primaryCTA()
                }
            } else {
                NavigationLink {
                    QuickSessionView(monthlyChallenge: challenge)
                } label: {
                    Text("Start the Challenge").primaryCTA(color: Theme.plum)
                }
            }
            Text(daysLeftText)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.inkSecondary)
        }
        .padding(20)
        .themedCard()
    }

    private var daysLeftText: String {
        let days = challenge.daysLeft()
        if days <= 1 { return "Last day of the \(challenge.monthName) challenge" }
        return "\(days) days left · a new challenge every month"
    }

    private var archive: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PAST MONTHS")
                .font(.caption.weight(.heavy))
                .kerning(1.4)
                .foregroundStyle(Theme.inkSecondary)
                .padding(.horizontal, 4)
            VStack(spacing: 0) {
                ForEach(pastMonths, id: \.self) { month in
                    archiveRow(MonthlyChallengeContent.challenge(for: month))
                    if month != pastMonths.last {
                        Divider().overlay(Theme.rule)
                    }
                }
            }
            .themedCard(corner: 16)
        }
    }

    private func archiveRow(_ past: MonthlyChallenge) -> some View {
        let result = store.result(for: past)
        return NavigationLink {
            if let result {
                MonthlyChallengeResultView(result: result)
            } else {
                QuickSessionView(monthlyChallenge: past)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: result == nil ? "play.circle" : "checkmark.seal.fill")
                    .foregroundStyle(result == nil ? Theme.plum : Theme.jade)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 1) {
                    Text(past.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.ink)
                    Text(past.theme.title)
                        .font(.caption)
                        .foregroundStyle(Theme.inkSecondary)
                }
                Spacer()
                Text(result.map { "\($0.score)/\($0.total)" } ?? "Play")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(result == nil ? Theme.plum : Theme.jade)
                    .monospacedDigit()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.inkTertiary)
            }
            .padding(14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct MonthlyChallengeResultView: View {
    let result: MonthlyChallengeResult
    var recordsCompletion = false
    var onDone: (() -> Void)?

    @EnvironmentObject private var progress: ProgressStore
    @EnvironmentObject private var subscriptions: SubscriptionService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview
    @State private var recorded = false
    @State private var showReviewPrompt = false
    @State private var showPaywall = false
    @State private var confettiTrigger = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                scoreCard
                if !subscriptions.isPro { memberCard }
                ShareLink(item: result.shareText) {
                    Label("Share Result", systemImage: "square.and.arrow.up")
                        .primaryCTA(color: Theme.plum)
                }
                Button("Done") {
                    if let onDone { onDone() } else { dismiss() }
                }
                .font(.headline)
                .foregroundStyle(Theme.inkSecondary)
                .padding(.vertical, 8)
            }
            .padding()
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.background)
        .overlay { ConfettiBurst(trigger: confettiTrigger, origin: .init(x: 0.5, y: 0.22), particleCount: 44) }
        .navigationTitle("Monthly Challenge")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(recordsCompletion)
        .onAppear { recordCompletionIfNeeded() }
        .sheet(isPresented: $showPaywall) { PaywallView(source: "monthly_challenge_result") }
        .sheet(isPresented: $showReviewPrompt) {
            ReviewPromptSheet { outcome in
                guard outcome.wantsSystemReviewPrompt else { return }
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 700_000_000)
                    requestReview()
                }
            }
        }
    }

    private var scoreCard: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Theme.jade.opacity(0.12))
                    .frame(width: 122, height: 122)
                VStack(spacing: 1) {
                    Text("\(result.score)/\(result.total)")
                        .font(Theme.display(34))
                        .foregroundStyle(Theme.jade)
                        .monospacedDigit()
                    Text("right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.inkSecondary)
                }
            }
            Text(result.score == result.total ? "A perfect month!" : "Challenge complete")
                .font(Theme.display(28))
                .foregroundStyle(Theme.ink)
            Text("\(result.title) Challenge: \(result.theme.title)")
                .font(.subheadline)
                .foregroundStyle(Theme.inkSecondary)
            HStack(spacing: 5) {
                ForEach(Array(result.answers.enumerated()), id: \.offset) { _, correct in
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(correct ? Theme.jade : Theme.well)
                        .frame(width: 16, height: 16)
                }
            }
            .padding(.top, 4)
            .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .themedCard()
    }

    /// Free players finished a real session of member-grade questions; this
    /// is the honest moment to say where more of them live.
    private var memberCard: some View {
        Button { showPaywall = true } label: {
            HStack(spacing: 12) {
                Image(systemName: result.theme.icon)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.plum)
                    .frame(width: 38, height: 38)
                    .background(Theme.plum.opacity(0.13), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Want more like these?")
                        .font(.headline)
                        .foregroundStyle(Theme.ink)
                    Text("\(Membership.name) deals fresh racks, passes and defense questions every day, without end.")
                        .font(.caption)
                        .foregroundStyle(Theme.inkSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.inkTertiary)
            }
            .padding(14)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableCardStyle())
        .themedCard(corner: 16)
    }

    private func recordCompletionIfNeeded() {
        guard recordsCompletion, !recorded else { return }
        recorded = true
        confettiTrigger += 1
        Haptics.success()
        SoundPlayer.play(.complete)
        progress.recordSession(drillID: MonthlyChallengeContent.drill.id)
        ReviewPromptTracker.recordPositiveMoment()
        guard ReviewPromptTracker.shouldShowAfterPositiveMoment() else { return }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_400_000_000)
            showReviewPrompt = true
        }
    }
}
