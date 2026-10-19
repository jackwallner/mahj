import SwiftUI
import UserNotifications

/// The monthly challenge: free for every player, built from each day's Mahj
/// Minute (five new questions, the same for everyone). The best 20 days make
/// the month score. The App Store in-app event for each month opens here through
/// `mahj://challenge`, and before the first month opens it says when.
struct MonthlyChallengeView: View {
    @StateObject private var store = MonthlyChallengeStore.shared
    @StateObject private var minuteStore = MahjMinuteStore.shared

    var body: some View {
        // One read of "today" per render: a round tapped just after midnight
        // still opens the day it was showing.
        let round = MonthlyChallengeContent.currentRound()
        ScrollView {
            VStack(spacing: 16) {
                if let round {
                    hero(round)
                    if round.month.daysLeft() <= 3 { MonthlyChallengeNextUp(after: round.month) }
                } else {
                    upcoming
                }
                let past = round.map { MonthlyChallengeContent.pastMonths(before: $0.month.start) } ?? []
                if !past.isEmpty { archive(past) }
                if !minuteStore.results.isEmpty { earlierMinutes }
            }
            .padding()
            .frame(maxWidth: Theme.readableContentWidth)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.background)
        .navigationTitle("\(round?.month.monthName ?? MonthlyChallengeContent.firstChallenge().monthName) Challenge")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            store.closeEarlierRounds(than: round)
            if let round { await ChallengeStandingService.refresh(monthKey: round.monthKey) }
        }
    }

    private func hero(_ round: ChallengeRound) -> some View {
        let month = round.month
        let score = store.monthScore(month.monthKey)
        let result = store.result(for: round)
        let progress = store.progress(for: round)
        return VStack(spacing: 14) {
            Image(systemName: month.theme.icon)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Theme.plum)
                .frame(width: 68, height: 68)
                .background(Theme.plum.opacity(0.13), in: Circle())
                .accessibilityHidden(true)
            VStack(spacing: 5) {
                Text("\(month.monthName.uppercased()) CHALLENGE")
                    .font(.caption.weight(.heavy))
                    .kerning(1.4)
                    .foregroundStyle(Theme.plum)
                Text(month.theme.title)
                    .font(Theme.display(27))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                if score.daysPlayed == 0 {
                    Text(month.theme.blurb)
                        .font(.subheadline)
                        .foregroundStyle(Theme.inkSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            if score.daysPlayed > 0 {
                MonthScoreSummary(score: score, standing: store.standing(for: month.monthKey))
            }
            MonthDaysStrip(month: month, today: round.day, results: store.results(inMonth: month.monthKey))
            if let result {
                todayDone(round, result)
            } else {
                NavigationLink {
                    QuickSessionView(monthlyRound: round, resume: progress)
                } label: {
                    Text(progress == nil ? "Play Today's Mahj Minute" : "Resume Today's Mahj Minute")
                        .primaryCTA(color: Theme.plum)
                }
            }
            Text(footnote(month))
                .font(.caption)
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .themedCard()
    }

    private func todayDone(_ round: ChallengeRound, _ result: MonthlyChallengeResult) -> some View {
        let lastDay = round.day >= round.month.dayCount
        return VStack(spacing: 10) {
            HStack(spacing: 10) {
                Text("Today")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                MonthlyChallengeGrid(answers: result.answers)
                Text("\(result.score)/\(result.total)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(result.score == result.total ? Theme.jade : Theme.ink)
                    .monospacedDigit()
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Today: \(result.score) of \(result.total) right")
            Text(lastDay
                 ? "That was the last round of \(round.month.monthName)."
                 : "Day \(round.day + 1) opens tomorrow.")
                .font(.subheadline)
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
            if result.matches(round) {
                NavigationLink {
                    MonthlyChallengeAnswersView(round: round, result: result)
                } label: {
                    Text(result.score == result.total ? "Review Today's Answers" : "See What You Missed")
                        .font(.headline)
                        .foregroundStyle(Theme.plum)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Theme.plum.opacity(0.1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
    }

    private func footnote(_ month: MonthlyChallenge) -> String {
        let days = month.daysLeft()
        let end = days <= 1 ? "Today is the last day." : "Runs through \(month.monthName)\u{00A0}\(month.dayCount)."
        return "Each square is a day's Mahj Minute: \(MonthlyChallengeContent.questionsPerRound) new questions, the same for every player. Every right answer is a point, and your best \(MonthlyChallengeContent.countedDays) days make your month score, up to \(MonthlyChallengeContent.maxMonthPoints). Missed days are fine. \(end)"
    }

    /// Before the first month: what it is and when it starts, plus the one
    /// reminder. The App Store event can send people here early.
    private var upcoming: some View {
        let first = MonthlyChallengeContent.firstChallenge()
        return VStack(spacing: 14) {
            Image(systemName: first.theme.icon)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Theme.plum)
                .frame(width: 68, height: 68)
                .background(Theme.plum.opacity(0.13), in: Circle())
                .accessibilityHidden(true)
            VStack(spacing: 5) {
                Text("\(first.monthName.uppercased()) CHALLENGE")
                    .font(.caption.weight(.heavy))
                    .kerning(1.4)
                    .foregroundStyle(Theme.plum)
                Text(first.theme.title)
                    .font(Theme.display(27))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                Text(first.theme.blurb)
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text("Starts \(first.start.formatted(.dateTime.weekday(.wide).month(.wide).day())). A Mahj Minute every day: five new questions, the same for every player.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            MonthlyChallengeReminderButton(nextMonthName: first.monthName)
        }
        .padding(20)
        .themedCard()
    }

    private func archive(_ months: [Date]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PAST MONTHS")
                .font(.caption.weight(.heavy))
                .kerning(1.4)
                .foregroundStyle(Theme.inkSecondary)
                .padding(.horizontal, 4)
            VStack(spacing: 0) {
                ForEach(months, id: \.self) { month in
                    archiveRow(month)
                    if month != months.last {
                        Divider().overlay(Theme.rule)
                    }
                }
            }
            .themedCard(corner: 16)
        }
    }

    private func archiveRow(_ month: Date) -> some View {
        let past = MonthlyChallengeContent.challenge(for: month)
        let score = store.monthScore(past.monthKey)
        return HStack(spacing: 12) {
            Image(systemName: past.theme.icon)
                .foregroundStyle(score.daysPlayed > 0 ? Theme.plum : Theme.inkTertiary)
                .frame(width: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text(past.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.ink)
                Text(past.theme.title)
                    .font(.caption)
                    .foregroundStyle(Theme.inkSecondary)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 1) {
                Text(score.daysPlayed > 0 ? "\(score.points)\u{00A0}points" : "Not played")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(score.daysPlayed > 0 ? Theme.plum : Theme.inkTertiary)
                    .monospacedDigit()
                if score.daysPlayed > 0 {
                    Text("\(score.daysPlayed)\u{00A0}\(score.daysPlayed == 1 ? "day" : "days")")
                        .font(.caption)
                        .foregroundStyle(Theme.inkSecondary)
                }
            }
        }
        .padding(14)
        .accessibilityElement(children: .combine)
    }

    /// Minutes played before they counted toward the month (1.4.1 and
    /// earlier), kept so a member's history does not vanish.
    private var earlierMinutes: some View {
        NavigationLink {
            MahjMinuteHistoryView()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "calendar.badge.clock")
                    .foregroundStyle(Theme.coral)
                    .frame(width: 28)
                    .accessibilityHidden(true)
                Text("Earlier Mahj Minutes")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.ink)
                Spacer(minLength: 8)
                Text("\(minuteStore.results.count)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.inkSecondary)
                    .monospacedDigit()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.inkTertiary)
                    .accessibilityHidden(true)
            }
            .padding(14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .themedCard(corner: 16)
    }
}

/// Points, days played and, once enough people have played, the standing.
/// Side by side, or stacked when large text will not fit them in a row.
private struct MonthScoreSummary: View {
    let score: MonthScore
    let standing: ChallengeStanding?

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) { pills }
            VStack(spacing: 8) { pills }
        }
    }

    @ViewBuilder
    private var pills: some View {
        pill("\(score.points)", "of \(MonthlyChallengeContent.maxMonthPoints) points")
        pill("\(score.daysPlayed)", score.daysPlayed == 1 ? "day played" : "days played")
        if let top = standing?.topPercent {
            pill("Top \(top)%", "this month")
        }
    }

    private func pill(_ value: String, _ label: String) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.headline)
                .foregroundStyle(Theme.ink)
                .monospacedDigit()
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.inkSecondary)
        }
        .fixedSize()
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Theme.plum.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

/// The month at a glance: one square per day. Played days fill with their
/// score, today is ringed, and days still to come are faint. A missed day
/// stays empty and costs nothing while fewer than 20 count.
private struct MonthDaysStrip: View {
    let month: MonthlyChallenge
    let today: Int
    let results: [MonthlyChallengeResult]
    @ScaledMetric(relativeTo: .body) private var side: CGFloat = 16

    var body: some View {
        let scores = Dictionary(uniqueKeysWithValues: results.map { ($0.day, $0.score) })
        let rows = stride(from: 1, through: month.dayCount, by: 10).map { Array($0...min($0 + 9, month.dayCount)) }
        VStack(spacing: 5) {
            ForEach(rows, id: \.first) { row in
                HStack(spacing: 5) {
                    ForEach(row, id: \.self) { day in
                        square(day: day, score: scores[day])
                    }
                    // Keeps a short last row aligned under the full ones.
                    ForEach(row.count..<10, id: \.self) { _ in Color.clear.frame(width: side, height: side) }
                }
            }
        }
        .accessibilityElement()
        .accessibilityLabel("\(results.count) of \(today) days played so far")
    }

    private func square(day: Int, score: Int?) -> some View {
        let fill: Color = {
            // A day not played looks like one still to come: nothing to
            // make up, and a late starter is not shown as behind.
            guard let score else { return Theme.rule.opacity(0.25) }
            let share = Double(min(score, MonthlyChallengeContent.questionsPerRound)) / Double(MonthlyChallengeContent.questionsPerRound)
            return score == 0 ? Theme.coral.opacity(0.14) : Theme.jade.opacity(0.25 + 0.75 * share)
        }()
        return RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(fill)
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(day == today ? Theme.plum : (score == 0 ? Theme.coral : .clear), lineWidth: day == today ? 2 : 1.5)
            )
            .frame(width: side, height: side)
    }
}

/// One square per answer, the same shape as the shared text.
/// Misses are outlined in coral so a low score reads as what it is.
struct MonthlyChallengeGrid: View {
    let answers: [Bool]
    @ScaledMetric(relativeTo: .body) private var side: CGFloat = 18

    var body: some View {
        VStack(spacing: 5) {
            ForEach(Array(stride(from: 0, to: answers.count, by: 6)), id: \.self) { start in
                HStack(spacing: 5) {
                    ForEach(start..<min(start + 6, answers.count), id: \.self) { index in
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(answers[index] ? Theme.jade : Theme.coral.opacity(0.14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .strokeBorder(answers[index] ? Color.clear : Theme.coral, lineWidth: 1.5)
                            )
                            .frame(width: side, height: side)
                    }
                }
            }
        }
        .accessibilityElement()
        .accessibilityLabel("\(answers.filter { $0 }.count) right, \(answers.filter { !$0 }.count) missed")
    }
}

/// After this month is done: what comes next and when, plus the one reminder.
private struct MonthlyChallengeNextUp: View {
    let after: MonthlyChallenge

    var body: some View {
        let next = MonthlyChallengeContent.next(after: after)
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: next.theme.icon)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.plum)
                    .frame(width: 38, height: 38)
                    .background(Theme.plum.opacity(0.13), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .accessibilityHidden(true)
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
                Label(isOn ? "Reminder On · 1st of Each Month" : "Remind Me When \(nextMonthName) Opens",
                      systemImage: isOn ? "bell.fill" : "bell")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isOn ? Theme.jade : Theme.plum)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background((isOn ? Theme.jade : Theme.plum).opacity(0.1),
                                in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityHint(isOn ? "Turns the monthly reminder off" : "Sends one notification on the 1st of each month")
            .task {
                // Notifications switched off in iOS Settings: say so rather
                // than show a reminder that will never arrive.
                guard isOn else { return }
                let settings = await UNUserNotificationCenter.current().notificationSettings()
                if settings.authorizationStatus == .denied {
                    isOn = false
                    denied = true
                }
            }
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
    let round: ChallengeRound
    let result: MonthlyChallengeResult
    var recordsCompletion = false
    var onDone: (() -> Void)?

    @EnvironmentObject private var subscriptions: SubscriptionService
    @StateObject private var store = MonthlyChallengeStore.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .largeTitle) private var circle: CGFloat = 122
    @State private var recorded = false
    @State private var reviewMoment = 0
    @State private var showPaywall = false
    @State private var confettiTrigger = 0

    private var fraction: Double { Double(result.score) / Double(max(result.total, 1)) }
    private var tone: Color {
        if fraction >= 0.75 { return Theme.jade }
        if fraction >= 0.5 { return Theme.gold }
        return Theme.coral
    }
    private var month: MonthScore { store.monthScore(round.monthKey) }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                scoreCard
                if result.matches(round) {
                    NavigationLink {
                        MonthlyChallengeAnswersView(round: round, result: result)
                    } label: {
                        Text(result.score == result.total ? "Review Your Answers" : "See What You Missed")
                            .primaryCTA(color: Theme.plum)
                    }
                }
                ShareLink(item: shareText) {
                    Label("Share Your Score", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .foregroundStyle(Theme.plum)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Theme.plum.opacity(0.1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                MahjPlusPitchCard(
                    headline: "Want more than five a day?",
                    detail: "\(Membership.name) adds unlimited hands in Play a Hand, Endless Practice, Game Night Prep and the Master Tables."
                ) { showPaywall = true }
            }
            .padding()
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.background)
        .overlay { ConfettiBurst(trigger: confettiTrigger, origin: .init(x: 0.5, y: 0.22), particleCount: 44) }
        .navigationTitle(result.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(recordsCompletion)
        .toolbar {
            if recordsCompletion {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        if let onDone { onDone() } else { dismiss() }
                    }
                    .font(.headline)
                }
            }
        }
        .onAppear { recordCompletionIfNeeded() }
        .task { await ChallengeStandingService.refresh(monthKey: round.monthKey, force: recordsCompletion) }
        .sheet(isPresented: $showPaywall) { PaywallView(source: "mahj_minute_result") }
        .requestsReview(after: reviewMoment, isClear: { !showPaywall })
    }

    private var verdict: String {
        if result.score == result.total { return "A perfect Minute!" }
        return fraction >= 0.6 ? "Solid Minute" : "A tough one"
    }

    private var monthLine: String {
        let points = "\(month.points)\u{00A0}\(month.points == 1 ? "point" : "points") in the \(round.month.monthName) Challenge"
        if let top = store.standing(for: round.monthKey)?.topPercent {
            return "+\(result.score) today · \(points) · Top\u{00A0}\(top)%"
        }
        return "+\(result.score) today · \(points)"
    }

    private var shareText: String {
        let squares = result.answers.map { $0 ? "🟩" : "⬜️" }.joined()
        return "Mahj Minute, \(result.title)\n\(squares) · \(month.points) points in the \(result.monthName) Challenge\nFive new questions a day, the same for every player: \(AppStoreLinks.productURL.absoluteString)"
    }

    private var scoreCard: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(tone.opacity(0.12))
                    .frame(width: circle, height: circle)
                VStack(spacing: 1) {
                    Text("\(result.score)/\(result.total)")
                        .font(Theme.display(34))
                        .foregroundStyle(fraction >= 0.5 && fraction < 0.75 ? Theme.goldText : tone)
                        .monospacedDigit()
                    Text("right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.inkSecondary)
                }
            }
            Text(verdict)
                .font(Theme.display(28))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(monthLine)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.plum)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            MonthlyChallengeGrid(answers: result.answers)
                .padding(.top, 2)
            Text(round.day >= round.month.dayCount
                 ? "That was the last round of \(round.month.monthName)."
                 : "A new Mahj Minute tomorrow.")
                .font(.subheadline)
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .themedCard()
    }

    private func recordCompletionIfNeeded() {
        guard recordsCompletion, !recorded else { return }
        recorded = true
        if fraction >= 0.5 {
            confettiTrigger += 1
            Haptics.success()
        }
        SoundPlayer.play(.complete)
        // The session and streak were banked with the last answer
        // (`QuickSessionView.grade`), so a round closed before this screen
        // still counts.
        guard fraction >= 0.5 else { return }
        reviewMoment += 1
    }
}

/// Every question of a finished round with all its choices marked, the
/// coaching, and why the player's pick was wrong. The score is locked, so
/// this is where a round turns into something learned.
struct MonthlyChallengeAnswersView: View {
    let round: ChallengeRound
    let result: MonthlyChallengeResult
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var missedOnly: Bool

    init(round: ChallengeRound, result: MonthlyChallengeResult) {
        self.round = round
        self.result = result
        _missedOnly = State(initialValue: result.score < result.total)
    }

    private var shown: [(index: Int, item: QuickItem)] {
        round.items.prefix(result.total).enumerated()
            .map { (index: $0.offset, item: $0.element) }
            .filter { !missedOnly || !(result.answers.indices.contains($0.index) && result.answers[$0.index]) }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                if result.score < result.total {
                    Picker("Show", selection: $missedOnly) {
                        Text("Missed (\(result.total - result.score))").tag(true)
                        Text("All \(result.total)").tag(false)
                    }
                    .pickerStyle(.segmented)
                }
                ForEach(shown, id: \.item.id) { entry in
                    answerCard(index: entry.index, item: entry.item)
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
        // At the largest text sizes the header stacks, or "QUESTION 1" and
        // the skill name break into word fragments beside each other.
        let header = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout(spacing: 8))
        return VStack(alignment: .leading, spacing: 12) {
            header {
                HStack(spacing: 8) {
                    Image(systemName: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(correct ? Theme.jade : Theme.coral)
                        .accessibilityHidden(true)
                    Text("QUESTION \(index + 1)")
                        .font(.caption.weight(.heavy))
                        .kerning(1.2)
                        .foregroundStyle(Theme.inkSecondary)
                        .fixedSize()
                }
                if !dynamicTypeSize.isAccessibilitySize { Spacer() }
                Text(MonthlyChallengeContent.skillTitle(of: item))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.inkTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Question \(index + 1), \(correct ? "right" : "missed"), \(MonthlyChallengeContent.skillTitle(of: item))")
            Text(item.prompt)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            if !item.tiles.isEmpty {
                TileRackView(tiles: item.tiles, tileWidth: dynamicTypeSize.isAccessibilitySize ? 36 : 30)
                    .frame(maxWidth: .infinity)
                    // One element: without this every tile inherited the
                    // whole rack's label and VoiceOver read it 13 times over.
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Rack: " + item.tiles.map(\.spokenName).joined(separator: ", "))
            }
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(item.choices.enumerated()), id: \.offset) { choice, label in
                    choiceRow(label, isAnswer: choice == item.answerIndex, isPick: choice == pick)
                }
            }
            Text(item.explanation)
                .font(.footnote)
                .foregroundStyle(Theme.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
            if let pick, pick != item.answerIndex, item.choices.indices.contains(pick),
               let reason = item.note(forPick: pick) {
                MissNoteCard(note: MissNote(pickedLabel: item.choices[pick], reason: reason))
            }
        }
        .padding(16)
        .themedCard(corner: 16)
    }

    private func choiceRow(_ label: String, isAnswer: Bool, isPick: Bool) -> some View {
        let color: Color = isAnswer ? Theme.jade : (isPick ? Theme.coral : Theme.inkTertiary)
        return HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: isAnswer ? "checkmark" : (isPick ? "xmark" : "circle"))
                .font(.caption.weight(.bold))
                .foregroundStyle(color)
                .frame(width: 16)
                .accessibilityHidden(true)
            // "your pick" goes under the label at the largest sizes, where a
            // third column leaves the answer a word per line.
            let stack = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
                : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 8))
            stack {
                Text(label)
                    .font(.subheadline.weight(isAnswer || isPick ? .semibold : .regular))
                    .foregroundStyle(isAnswer || isPick ? color : Theme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                if isPick {
                    Text("your pick")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Theme.inkTertiary)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label)\(isAnswer ? ", the answer" : "")\(isPick ? ", your pick" : "")")
    }
}
