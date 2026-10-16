import SwiftUI
import UserNotifications

/// The monthly challenge: free for every player, the same twelve questions on
/// every device, one attempt a month. The App Store in-app event for each
/// month opens here through `mahj://challenge`. Past months open the same
/// screen for their own month.
struct MonthlyChallengeView: View {
    /// Nil for the current month.
    var month: Date?

    @StateObject private var store = MonthlyChallengeStore.shared

    private var challenge: MonthlyChallenge {
        MonthlyChallengeContent.challenge(for: month ?? MonthlyChallengeContent.today)
    }
    private var isCurrent: Bool { challenge.monthKey == MonthlyChallengeContent.challenge().monthKey }
    private var pastMonths: [Date] { isCurrent ? MonthlyChallengeContent.pastMonths() : [] }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                hero
                if isCurrent, store.result(for: challenge) != nil {
                    MonthlyChallengeNextUp(after: challenge)
                }
                if !pastMonths.isEmpty { archive }
            }
            .padding()
            .frame(maxWidth: Theme.readableContentWidth)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.background)
        .navigationTitle(isCurrent ? challenge.monthName : challenge.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var hero: some View {
        // One month for the whole card: a Resume tapped just after midnight
        // on the 1st must finish the month its saved answers belong to.
        let challenge = challenge
        let result = store.result(for: challenge)
        let progress = store.progress(for: challenge)
        return VStack(spacing: 14) {
            Image(systemName: result == nil ? challenge.theme.icon : "checkmark.seal.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(result == nil ? Theme.plum : Theme.jade)
                .frame(width: 68, height: 68)
                .background((result == nil ? Theme.plum : Theme.jade).opacity(0.13), in: Circle())
                .accessibilityHidden(true)
            VStack(spacing: 5) {
                Text("\(challenge.monthName.uppercased()) CHALLENGE")
                    .font(.caption.weight(.heavy))
                    .kerning(1.4)
                    .foregroundStyle(Theme.plum)
                Text(challenge.theme.title)
                    .font(Theme.display(27))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                if result == nil {
                    Text(challenge.theme.blurb)
                        .font(.subheadline)
                        .foregroundStyle(Theme.inkSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            if let result {
                MonthlyChallengeGrid(answers: result.answers)
                NavigationLink {
                    MonthlyChallengeResultView(result: result)
                } label: {
                    Text("See Your Results").primaryCTA()
                }
            } else {
                MonthlyChallengeMix(challenge: challenge)
                NavigationLink {
                    QuickSessionView(monthlyChallenge: challenge, resume: progress)
                } label: {
                    Text(progress.map { "Resume at Question \($0.answers.count + 1)" } ?? "Start the Challenge")
                        .primaryCTA(color: Theme.plum)
                }
            }
            Text(footnote(result: result, progress: progress))
                .font(.caption)
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .themedCard()
    }

    private func footnote(result: MonthlyChallengeResult?, progress: MonthlyChallengeProgress?) -> String {
        guard isCurrent else {
            return result == nil
                ? "From \(challenge.title). Each answer counts as soon as you tap it, and your answers are saved if you stop."
                : "From \(challenge.title). Your score is final."
        }
        let next = MonthlyChallengeContent.next(after: challenge)
        let days = challenge.daysLeft()
        let left = days <= 1 ? "Last day" : "\(days)\u{00A0}days left"
        if result != nil {
            return days <= 1
                ? "Your score is final. \(next.monthName) opens tomorrow."
                : "Your score is final. \(next.monthName) opens in \(days)\u{00A0}days."
        }
        if progress != nil {
            let last = challenge.end.addingTimeInterval(-1).formatted(.dateTime.month(.wide).day())
            return "Your answers are saved. Pick up any time through \(last)."
        }
        return "Each answer counts as soon as you tap it. Stop any time and your answers are saved. \(left)."
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
                    archiveRow(month)
                    if month != pastMonths.last {
                        Divider().overlay(Theme.rule)
                    }
                }
            }
            .themedCard(corner: 16)
        }
    }

    private func archiveRow(_ month: Date) -> some View {
        let past = MonthlyChallengeContent.challenge(for: month)
        let result = store.result(for: past)
        let progress = store.progress(for: past)
        return NavigationLink {
            MonthlyChallengeView(month: month)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: result == nil ? past.theme.icon : "checkmark.seal.fill")
                    .foregroundStyle(result == nil ? Theme.plum : Theme.jade)
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
                Spacer()
                Text(result.map { "\($0.score)/\($0.total)" } ?? (progress == nil ? "Play" : "Resume"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(result == nil ? Theme.plum : Theme.jade)
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
    }
}

/// What the twelve questions are made of, so the theme is a promise the
/// player can count: "8 Charleston · 2 Safe Discards · 2 Reading Your Rack", the theme
/// first and in its colour. Plain text, so it wraps at any text size.
private struct MonthlyChallengeMix: View {
    let challenge: MonthlyChallenge

    var body: some View {
        let counts = Dictionary(grouping: challenge.items, by: MonthlyChallengeContent.skill(of:)).mapValues(\.count)
        let others = MonthlyChallengeTheme.allCases
            .filter { $0 != challenge.theme && counts[$0, default: 0] > 0 }
            .map { "\(counts[$0, default: 0])\u{00A0}\($0.skillTitle.replacingOccurrences(of: " ", with: "\u{00A0}"))" }
        let lead = "\(counts[challenge.theme, default: 0])\u{00A0}\(challenge.theme.skillTitle.replacingOccurrences(of: " ", with: "\u{00A0}"))"
        (Text(lead).foregroundStyle(Theme.plum).fontWeight(.bold)
            + Text(others.map { " · \($0)" }.joined()).foregroundStyle(Theme.inkSecondary))
            .font(.subheadline.weight(.semibold))
            .multilineTextAlignment(.center)
            .accessibilityLabel(([lead] + others).joined(separator: ", ").replacingOccurrences(of: "\u{00A0}", with: " "))
    }
}

/// Twelve squares in two rows of six, the same shape as the shared text.
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
    let result: MonthlyChallengeResult
    var recordsCompletion = false
    var onDone: (() -> Void)?

    @EnvironmentObject private var subscriptions: SubscriptionService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .largeTitle) private var circle: CGFloat = 122
    @State private var recorded = false
    @State private var reviewMoment = 0
    @State private var showPaywall = false
    @State private var confettiTrigger = 0

    private var challenge: MonthlyChallenge? { MonthlyChallengeContent.challenge(monthKey: result.monthKey) }
    private var fraction: Double { Double(result.score) / Double(max(result.total, 1)) }
    private var tone: Color {
        if fraction >= 0.75 { return Theme.jade }
        if fraction >= 0.5 { return Theme.gold }
        return Theme.coral
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                scoreCard
                if let challenge, result.matches(challenge) {
                    breakdown(challenge)
                    NavigationLink {
                        MonthlyChallengeAnswersView(challenge: challenge, result: result)
                    } label: {
                        Text(result.score == result.total ? "Review Your Answers" : "See What You Missed")
                            .primaryCTA(color: Theme.plum)
                    }
                } else {
                    Text("This month's questions were updated after you played, so your score is kept but the answer review is not.")
                        .font(.caption)
                        .foregroundStyle(Theme.inkSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                ShareLink(item: result.shareText) {
                    Label("Share Your Score", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .foregroundStyle(Theme.plum)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Theme.plum.opacity(0.1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                if !subscriptions.isPro { memberCard }
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
        .sheet(isPresented: $showPaywall) { PaywallView(source: "monthly_challenge_result") }
        .requestsReview(after: reviewMoment, isClear: { !showPaywall })
    }

    private var verdict: String {
        switch fraction {
        case 1: return "A perfect month!"
        case 0.75...: return "Sharp play"
        case 0.5...: return "Solid month"
        default: return "A tough one"
        }
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
                        .foregroundStyle(tone)
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
            Text(fraction < 0.5 ? "Every miss is explained below." : result.theme.title)
                .font(.subheadline)
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
            MonthlyChallengeGrid(answers: result.answers)
                .padding(.top, 2)
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
                    let line = dynamicTypeSize.isAccessibilitySize
                        ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
                        : AnyLayout(HStackLayout(spacing: 12))
                    line {
                        if !dynamicTypeSize.isAccessibilitySize {
                            Image(systemName: skill.icon)
                                .foregroundStyle(Theme.inkSecondary)
                                .frame(width: 30)
                                .accessibilityHidden(true)
                        }
                        Text(skill.skillTitle)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        if !dynamicTypeSize.isAccessibilitySize { Spacer(minLength: 8) }
                        Text("\(right)/\(rows.count)")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(color(right, of: rows.count))
                            .monospacedDigit()
                            .fixedSize()
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .padding(16)
        .themedCard(corner: 16)
    }

    private func color(_ right: Int, of total: Int) -> Color {
        if right == total { return Theme.jade }
        if right * 2 >= total { return Theme.ink }
        return Theme.coral
    }

    /// Free players just finished a real session of member-grade questions;
    /// this is the honest moment to say where more of them live.
    private var memberCard: some View {
        Button { showPaywall = true } label: {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 8) {
                        memberIcon
                        memberText
                    }
                } else {
                    HStack(spacing: 12) {
                        memberIcon
                        memberText
                        Spacer(minLength: 4)
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.inkTertiary)
                            .accessibilityHidden(true)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableCardStyle())
        .themedCard(corner: 16)
    }

    private var memberIcon: some View {
        Image(systemName: "infinity")
            .font(.body.weight(.semibold))
            .foregroundStyle(Theme.jade)
            .frame(width: 38, height: 38)
            .background(Theme.jade.opacity(0.13), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .accessibilityHidden(true)
    }

    private var memberText: some View {
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
        // (`QuickSessionView.grade`), so a run closed before this screen
        // still counts.
        guard fraction >= 0.5 else { return }
        reviewMoment += 1
    }
}

/// Every question of a finished month with all its choices marked, the
/// coaching, and why the player's pick was wrong. The score is locked, so
/// this is where a run turns into something learned.
struct MonthlyChallengeAnswersView: View {
    let challenge: MonthlyChallenge
    let result: MonthlyChallengeResult
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var missedOnly: Bool

    init(challenge: MonthlyChallenge, result: MonthlyChallengeResult) {
        self.challenge = challenge
        self.result = result
        _missedOnly = State(initialValue: result.score < result.total)
    }

    private var shown: [(index: Int, item: QuickItem)] {
        challenge.items.enumerated()
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
                Text(MonthlyChallengeContent.skill(of: item).skillTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.inkTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Question \(index + 1), \(correct ? "right" : "missed"), \(MonthlyChallengeContent.skill(of: item).skillTitle)")
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
