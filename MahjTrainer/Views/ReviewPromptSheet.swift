import SwiftUI
import UIKit

/// How the funnel ended, so the host knows whether to fire `requestReview()`.
enum ReviewPromptDismissOutcome: Sendable {
    case notNow
    case feedbackSubmitted
    case openedWriteReview
    /// Said yes on the enjoyment step: the host fires `requestReview()`.
    case enjoyed
    /// Said yes, then "Maybe later": the host may fire `requestReview()` once.
    case enjoyedMaybeLater

    /// Whether the host should put Apple's own star prompt on screen.
    var wantsSystemReviewPrompt: Bool {
        self == .enjoyed || self == .enjoyedMaybeLater
    }
}

/// What the player is reporting when they tap "Something wrong?" under a
/// graded question. Carries enough to find the item without any typing.
struct QuestionReport: Hashable, Sendable {
    let itemID: String
    let prompt: String
    let source: String
    let tiles: String
}

/// The review funnel and every other place the app asks the player to type:
/// enjoying it? -> yes fires Apple's star prompt / no opens a feedback box;
/// a question report; the one question asked when a membership is leaving.
///
/// Nobody who says "not really" is ever shown a rating prompt. Unhappy
/// players get a box that goes straight to the developer, which is why the
/// App Store rating only ever hears from happy ones.
struct ReviewPromptSheet: View {
    enum Step: Identifiable, Hashable {
        case enjoyment, reviewPitch, feedback
        case question(QuestionReport)
        case churn(ChurnMoment)

        var id: Self { self }
    }

    let initialStep: Step
    let onFinish: (ReviewPromptDismissOutcome) -> Void

    @EnvironmentObject private var subscriptions: SubscriptionService
    @Environment(\.dismiss) private var dismiss
    @State private var step: Step
    @State private var feedbackText = ""
    @State private var chosenChip: String?
    @State private var sending = false
    @State private var sendOutcome: FeedbackService.Outcome?
    @FocusState private var feedbackFocused: Bool

    init(initialStep: Step = .enjoyment, onFinish: @escaping (ReviewPromptDismissOutcome) -> Void) {
        self.initialStep = initialStep
        self.onFinish = onFinish
        _step = State(initialValue: initialStep)
    }

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case .enjoyment: enjoymentContent
                case .reviewPitch: reviewPitchContent
                case .feedback:
                    composer(
                        kind: .general,
                        question: "What would make Mahj Trainer better for you?",
                        chips: [],
                        thanks: "Thanks. It went straight to the developer."
                    )
                case .question(let report):
                    composer(
                        kind: .question,
                        question: "What looks off about this question?",
                        chips: ["The answer seems wrong", "The explanation is confusing", "A typo or wording", "Something else"],
                        thanks: "Thanks. Every report is read, and the question gets fixed or explained better.",
                        context: [
                            "item_id": report.itemID,
                            "prompt": String(report.prompt.prefix(160)),
                            "source": report.source,
                            "tiles": report.tiles,
                        ]
                    )
                case .churn(let moment):
                    composer(
                        kind: .churn,
                        question: churnQuestion(moment),
                        chips: churnChips(moment),
                        thanks: "Thanks for saying. It helps more than you'd think.",
                        context: ["moment": moment.rawValue]
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Theme.background)
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(sendOutcome == nil ? "Not now" : "Done") {
                        if sendOutcome == nil, isFunnelStep { ReviewPromptTracker.markShown() }
                        finish(sendOutcome == nil ? .notNow : .feedbackSubmitted)
                    }
                    .foregroundStyle(Theme.inkSecondary)
                }
            }
        }
        .presentationDetents(isComposerStep ? [.large] : [.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var isComposerStep: Bool {
        switch step {
        case .enjoyment, .reviewPitch: return false
        case .feedback, .question, .churn: return true
        }
    }

    /// Only the review funnel's own steps touch the review tracker. A
    /// question report or a churn question says nothing about whether the
    /// player would rate the app.
    private var isFunnelStep: Bool {
        switch step {
        case .enjoyment, .reviewPitch, .feedback: return true
        case .question, .churn: return false
        }
    }

    private var navigationTitle: String {
        switch step {
        case .enjoyment: "Enjoying Mahj Trainer?"
        case .reviewPitch: "Support an indie app"
        case .feedback: "Help us improve"
        case .question: "Something wrong?"
        case .churn(let moment): moment.isTrial ? "Before your trial ends" : "Before you go"
        }
    }

    // MARK: - Enjoyment

    private var enjoymentContent: some View {
        VStack(spacing: 20) {
            icon("checkmark.seal.fill", Theme.jade)
            Text("You've finished \(ReviewPromptTracker.positiveMomentCount) drills. If Mahj Trainer is helping the card stick between games, a quick rating helps other players find it.")
                .font(.subheadline)
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            VStack(spacing: 10) {
                Button {
                    // Apple's own prompt: stars in one tap, never leaves the
                    // app. Sending warm players out to the App Store page was
                    // the single biggest leak in the funnel.
                    ReviewPromptTracker.markEnjoyed()
                    finish(.enjoyed)
                } label: {
                    Text("Yes, I'm enjoying it").primaryCTA()
                }
                Button { step = .feedback } label: {
                    Text("Not really")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.inkSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
            }
        }
        .padding(24)
    }

    // MARK: - Review pitch (Settings > Rate)

    private var reviewPitchContent: some View {
        VStack(spacing: 18) {
            icon("star.fill", Theme.gold)
            Text("Mahj Trainer is built by one person. No ads, no accounts, and your practice history never leaves your phone.")
                .font(.subheadline)
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text("An honest App Store review takes a few seconds and is the single biggest thing that helps a small app like this reach new players.")
                .font(.footnote)
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            VStack(spacing: 10) {
                Button {
                    ReviewPromptTracker.markOpenedWriteReview()
                    UIApplication.shared.open(AppStoreLinks.writeReviewURL)
                    finish(.openedWriteReview)
                } label: {
                    Text("Write a review").primaryCTA()
                }
                Button {
                    ReviewPromptTracker.markSoftDeferred()
                    finish(.enjoyedMaybeLater)
                } label: {
                    Text("Just rate it")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.inkSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
            }
        }
        .padding(24)
    }

    // MARK: - Composer (feedback, question report, churn)

    private func composer(
        kind: FeedbackKind,
        question: String,
        chips: [String],
        thanks: String,
        context: [String: String] = [:]
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            if let sendOutcome {
                sentState(sendOutcome, thanks: thanks)
            } else {
                Text(question)
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if !chips.isEmpty {
                    chipRows(chips)
                }
                TextEditor(text: $feedbackText)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: chips.isEmpty ? 140 : 96)
                    .padding(10)
                    .themedCard(corner: 14)
                    .focused($feedbackFocused)
                    .overlay(alignment: .topLeading) {
                        if feedbackText.isEmpty {
                            Text(chips.isEmpty ? "Anything at all." : "Add a few words if you like.")
                                .font(.body)
                                .foregroundStyle(Theme.inkTertiary)
                                .padding(.horizontal, 15)
                                .padding(.vertical, 18)
                                .allowsHitTesting(false)
                        }
                    }
                Text("Goes straight to the developer, a real person. No account, no email needed.")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSecondary)
                Button {
                    send(kind: kind, context: context)
                } label: {
                    Group {
                        if sending {
                            ProgressView().tint(.white)
                        } else {
                            Text("Send")
                        }
                    }
                    .primaryCTA()
                }
                .disabled(!canSend || sending)
                .opacity(canSend ? 1 : 0.5)
            }
            Spacer(minLength: 0)
        }
        .padding(24)
        .onAppear { if chips.isEmpty { feedbackFocused = true } }
    }

    private func chipRows(_ chips: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(chips, id: \.self) { chip in
                let selected = chosenChip == chip
                Button {
                    chosenChip = selected ? nil : chip
                    Haptics.impact(.light, intensity: 0.5)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(selected ? Theme.jade : Theme.inkTertiary)
                        Text(chip)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Theme.ink)
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        selected ? Theme.jade.opacity(0.10) : Theme.card,
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(selected ? Theme.jade : Theme.rule, lineWidth: selected ? 1.5 : 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func sentState(_ outcome: FeedbackService.Outcome, thanks: String) -> some View {
        VStack(spacing: 16) {
            switch outcome {
            case .sent:
                icon("paperplane.fill", Theme.jade)
                Text(thanks)
                    .font(.subheadline)
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            case .queued:
                icon("tray.and.arrow.up.fill", Theme.gold)
                Text("Saved. It will send the next time you open the app with a connection.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            case .failed:
                icon("exclamationmark.triangle.fill", Theme.coral)
                Text("That didn't go through. You can email it instead:")
                    .font(.subheadline)
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                Button {
                    UIPasteboard.general.string = AppStoreLinks.feedbackEmail
                    Haptics.success()
                } label: {
                    Label("Copy \(AppStoreLinks.feedbackEmail)", systemImage: "doc.on.doc")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.jade)
                }
            }
            Button {
                finish(.feedbackSubmitted)
            } label: {
                Text("Done").primaryCTA()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
    }

    private var trimmedFeedback: String {
        feedbackText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSend: Bool {
        chosenChip != nil || !trimmedFeedback.isEmpty
    }

    private func send(kind: FeedbackKind, context: [String: String]) {
        guard canSend, !sending else { return }
        sending = true
        feedbackFocused = false
        var message = trimmedFeedback
        if let chosenChip {
            message = message.isEmpty ? chosenChip : "[\(chosenChip)] \(message)"
        }
        let isMember = subscriptions.isPro
        Task { @MainActor in
            let outcome = await FeedbackService.shared.submit(
                kind: kind,
                message: message,
                context: context,
                isMember: isMember
            )
            sending = false
            if outcome != .failed, isFunnelStep {
                ReviewPromptTracker.markFeedbackSubmitted()
            }
            if outcome == .sent { Haptics.success() }
            withAnimation(.easeOut(duration: 0.25)) { sendOutcome = outcome }
        }
    }

    // MARK: - Churn copy

    private func churnQuestion(_ moment: ChurnMoment) -> String {
        switch moment {
        case .trialRenewalOff: return "Your trial won't renew. What held you back?"
        case .trialLapsed: return "Your free week ended. What held you back from keeping Mahj+?"
        case .paidRenewalOff: return "Your membership won't renew. What would have kept you?"
        case .paidLapsed: return "Your membership ended. What would have kept you?"
        }
    }

    private func churnChips(_ moment: ChurnMoment) -> [String] {
        if moment.isTrial {
            return ["Too expensive", "Didn't use it enough", "Got what I needed", "Something was missing", "Something else"]
        }
        return ["Too expensive", "Not practicing enough anymore", "Learned what I needed", "Wanted more content", "Something else"]
    }

    // MARK: - Helpers

    private func icon(_ name: String, _ color: Color) -> some View {
        Image(systemName: name)
            .font(.system(size: 28, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: 68, height: 68)
            .background(color.opacity(0.13), in: Circle())
            .padding(.top, 6)
    }

    private func finish(_ outcome: ReviewPromptDismissOutcome) {
        onFinish(outcome)
        dismiss()
    }
}

/// The small "Something wrong with this question?" link under a graded
/// answer. Owns its own sheet so every drill gets it by passing a report.
struct ReportQuestionLink: View {
    let report: QuestionReport
    @State private var showing = false

    var body: some View {
        Button {
            showing = true
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "flag")
                    .font(.caption2)
                Text("Something wrong with this question?")
                    .font(.caption)
            }
            .foregroundStyle(Theme.inkTertiary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showing) {
            ReviewPromptSheet(initialStep: .question(report)) { _ in }
        }
    }
}
