import StoreKit
import SwiftUI

/// The monthly challenge: free for every player, the same twelve questions on
/// every device, one counted run a month. The App Store in-app event for each
/// month opens here through `mahj://challenge`.
struct MonthlyChallengeView: View {
    @StateObject private var store = MonthlyChallengeStore.shared

    private var challenge: MonthlyChallenge { MonthlyChallengeContent.challenge() }
    private var pastMonths: [Date] { MonthlyChallengeContent.pastMonths() }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                hero
                if let result = store.result(for: challenge) {
                    MonthlyChallengeNextUp(after: challenge, result: result)
                }
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

    private var hero: some View {
        let result = store.result(for: challenge)
        let progress = store.progress(for: challenge)
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
            }
            MonthlyChallengeMix(challenge: challenge)
            if let result {
                NavigationLink {
                    MonthlyChallengeResultView(result: result)
                } label: {
                    Text("View Your \(result.score)/\(result.total)").primaryCTA()
                }
            } else if let progress {
                NavigationLink {
                    QuickSessionView(monthlyChallenge: challenge, resume: progress)
                } label: {
                    Text("Resume: \(progress.answers.count) of \(challenge.items.count) Answered")
                        .primaryCTA(color: Theme.plum)
                }
            } else {
                NavigationLink {
                    QuickSessionView(monthlyChallenge: challenge)
                } label: {
                    Text("Start the Challenge").primaryCTA(color: Theme.plum)
                }
            }
            Text(footnote(done: result != nil))
                .font(.caption)
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .themedCard()
    }

    private func footnote(done: Bool) -> String {
        let days = challenge.daysLeft()
        let left = days <= 1 ? "Last day of the \(challenge.monthName) challenge." : "\(days) days left."
        if done { return left }
        return "Same questions for every player. Your first run is the one that counts. \(left)"
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
        let progress = store.progress(for: past)
        return NavigationLink {
            if let result {
                MonthlyChallengeResultView(result: result)
            } else {
                QuickSessionView(monthlyChallenge: past, resume: progress)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: result == nil ? past.theme.icon : "checkmark.seal.fill")
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
                Text(result.map { "\($0.score)/\($0.total)" } ?? (progress == nil ? "Play" : "Resume"))
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

/// What the twelve questions are made of, so the theme is a promise the
/// player can count: "6 Charleston · 2 Rack Reading · 4 Table Play".
private struct MonthlyChallengeMix: View {
    let challenge: MonthlyChallenge

    var body: some View {
        let counts = Dictionary(grouping: challenge.items, by: MonthlyChallengeContent.skill(of:)).mapValues(\.count)
        let ordered = [challenge.theme] + MonthlyChallengeTheme.allCases.filter { $0 != challenge.theme }
        HStack(spacing: 6) {
            ForEach(ordered.filter { counts[$0, default: 0] > 0 }, id: \.self) { skill in
                HStack(spacing: 4) {
                    Image(systemName: skill.icon)
                        .font(.caption2.weight(.semibold))
                    Text("\(counts[skill, default: 0]) \(skill.skillTitle)")
                        .font(.caption.weight(.semibold))
                        .monospacedDigit()
                }
                .foregroundStyle(skill == challenge.theme ? Theme.plum : Theme.inkSecondary)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background((skill == challenge.theme ? Theme.plum : Theme.well).opacity(skill == challenge.theme ? 0.12 : 1),
                            in: Capsule())
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// After this month is done: what comes next and when, plus the one reminder.
private struct MonthlyChallengeNextUp: View {
    let after: MonthlyChallenge
    let result: MonthlyChallengeResult

    var body: some View {
        let next = MonthlyChallengeContent.next(after: after)
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: next.theme.icon)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.plum)
                    .frame(width: 38, height: 38)
                    .background(Theme.plum.opacity(0.13), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text("NEXT UP")
                        .font(.caption2.weight(.heavy))
                        .kerning(1.2)
                        .foregroundStyle(Theme.inkSecondary)
                    Text("\(next.monthName): \(next.theme.title)")
                        .font(.headline)
                        .foregroundStyle(Theme.ink)
                    Text("Opens \(next.start.formatted(.dateTime.weekday(.wide).month(.wide).day())).")
                        .font(.caption)
                        .foregroundStyle(Theme.inkSecondary)
                }
                Spacer(minLength: 0)
            }
            MonthlyChallengeReminderButton(nextMonthName: next.monthName)
        }
        .padding(16)
        .themedCard(corner: 16)
    }
}

/// The player's own choice to hear about the next month. Never asked for
/// silently; a refusal is reported plainly with where to change it.
private struct MonthlyChallengeReminderButton: View {
    let nextMonthName: String
    @State private var isOn = MonthlyChallengeReminder.isOn
    @State private var denied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                if isOn {
                    MonthlyChallengeReminder.disable()
                    isOn = false
                } else {
                    MonthlyChallengeReminder.enable { granted in
                        isOn = granted
                        denied = !granted
                    }
                }
            } label: {
                Label(isOn ? "Reminder set for the 1st of each month" : "Remind me when \(nextMonthName)'s opens",
                      systemImage: isOn ? "bell.fill" : "bell")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isOn ? Theme.jade : Theme.plum)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background((isOn ? Theme.jade : Theme.plum).opacity(0.1),
                                in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityHint(isOn ? "Turns the monthly reminder off" : "Asks to send one notification on the 1st of each month")
            if denied {
                Text("Notifications are off for Mahj Trainer. Turn them on in Settings > Notifications to get the reminder.")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
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

    private var challenge: MonthlyChallenge? { MonthlyChallengeContent.challenge(monthKey: result.monthKey) }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                scoreCard
                if let challenge, challenge.items.count == result.answers.count {
                    breakdown(challenge)
                    NavigationLink {
                        MonthlyChallengeAnswersView(challenge: challenge, result: result)
                    } label: {
                        Label("Review Your Answers", systemImage: "list.bullet.rectangle")
                            .font(.headline)
                            .foregroundStyle(Theme.plum)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .themedCard(corner: 14)
                    }
                    .buttonStyle(PressableCardStyle())
                }
                ShareLink(item: result.shareText) {
                    Label("Share Result", systemImage: "square.and.arrow.up")
                        .primaryCTA(color: Theme.plum)
                }
                if let challenge, result.monthKey == MonthlyChallengeContent.challenge().monthKey {
                    MonthlyChallengeNextUp(after: challenge, result: result)
                }
                if !subscriptions.isPro { memberCard }
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

    private var verdict: String {
        switch Double(result.score) / Double(max(result.total, 1)) {
        case 1: return "A perfect month!"
        case 0.75...: return "Sharp play"
        case 0.5...: return "Solid month"
        default: return "Challenge complete"
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
            Text(verdict)
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

    private func breakdown(_ challenge: MonthlyChallenge) -> some View {
        let pairs = zip(challenge.items, result.answers).map { (MonthlyChallengeContent.skill(of: $0.0), $0.1) }
        let ordered = [challenge.theme] + MonthlyChallengeTheme.allCases.filter { $0 != challenge.theme }
        return VStack(alignment: .leading, spacing: 14) {
            Text("BY SKILL")
                .font(.caption.weight(.heavy))
                .kerning(1.4)
                .foregroundStyle(Theme.inkSecondary)
            ForEach(ordered, id: \.self) { skill in
                let rows = pairs.filter { $0.0 == skill }
                if !rows.isEmpty {
                    let right = rows.filter(\.1).count
                    HStack(spacing: 12) {
                        Image(systemName: skill.icon)
                            .foregroundStyle(color(right, of: rows.count))
                            .frame(width: 30)
                        Text(skill.skillTitle)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        Text("\(right)/\(rows.count)")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(color(right, of: rows.count))
                            .monospacedDigit()
                    }
                }
            }
        }
        .padding(16)
        .themedCard(corner: 16)
    }

    private func color(_ right: Int, of total: Int) -> Color {
        if right == total { return Theme.jade }
        if right > 0 { return Theme.gold }
        return Theme.coral
    }

    /// Free players just finished a real session of member-grade questions;
    /// this is the honest moment to say where more of them live.
    private var memberCard: some View {
        Button { showPaywall = true } label: {
            HStack(spacing: 12) {
                Image(systemName: "infinity")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.jade)
                    .frame(width: 38, height: 38)
                    .background(Theme.jade.opacity(0.13), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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

/// Every question of a finished month, with the player's pick, the right
/// answer and the coaching. The score is locked, so this is where a run turns
/// into something learned.
struct MonthlyChallengeAnswersView: View {
    let challenge: MonthlyChallenge
    let result: MonthlyChallengeResult

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(Array(challenge.items.enumerated()), id: \.element.id) { index, item in
                    answerCard(index: index, item: item)
                }
            }
            .padding()
            .frame(maxWidth: Theme.readableContentWidth)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.background)
        .navigationTitle("\(result.title) Answers")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func answerCard(index: Int, item: QuickItem) -> some View {
        let correct = result.answers.indices.contains(index) && result.answers[index]
        let pick = result.picks.flatMap { $0.indices.contains(index) ? $0[index] : nil }
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(correct ? Theme.jade : Theme.coral)
                Text("Question \(index + 1)")
                    .font(.caption.weight(.heavy))
                    .kerning(1.1)
                    .foregroundStyle(Theme.inkSecondary)
                Spacer()
                Text(MonthlyChallengeContent.skill(of: item).skillTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.inkTertiary)
            }
            Text(item.prompt)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            if !item.tiles.isEmpty {
                TileRackView(tiles: item.tiles, tileWidth: 30)
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel(item.tiles.map(\.spokenName).joined(separator: ", "))
            }
            VStack(alignment: .leading, spacing: 6) {
                if let pick, pick != item.answerIndex, item.choices.indices.contains(pick) {
                    answerLine("You picked", item.choices[pick], color: Theme.coral, icon: "xmark")
                }
                answerLine(correct ? "You picked" : "Answer", item.choices[item.answerIndex], color: Theme.jade, icon: "checkmark")
            }
            Text(item.explanation)
                .font(.footnote)
                .foregroundStyle(Theme.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
            if let pick, pick != item.answerIndex, let note = item.note(forPick: pick) {
                Text("Why not \(item.choices[pick])? \(note)")
                    .font(.footnote)
                    .foregroundStyle(Theme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .themedCard(corner: 16)
    }

    private func answerLine(_ label: String, _ value: String, color: Color, icon: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(color)
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.inkSecondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
