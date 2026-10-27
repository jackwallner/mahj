import SwiftUI

private enum QuickSessionPurpose {
    case quickSession(isDaily: Bool)
    case monthlyChallenge(ChallengeRound)
    case gameNightPrep

    var drill: Drill {
        switch self {
        case .quickSession: return SessionBuilder.sessionDrill
        case .monthlyChallenge: return MonthlyChallengeContent.drill
        case .gameNightPrep: return SessionBuilder.gameNightPrepDrill
        }
    }

    var navigationTitle: String {
        drill.title
    }
}

/// The Get Started session: a short, UNIFORM run of single-select choice
/// items pulled from across the rooms. Every item follows the same beat -
/// pick, grade immediately, the correct answer highlights and HOLDS, then an
/// explicit Next - so there's no interstitial or mixed grading path to fight
/// the transition. (The old MixedSessionView packed flip-flashcards, quiz,
/// and hand-match into one screen with a per-switch interstitial; that mix
/// of grading paths is what made it look like it skipped the right answer.)
struct QuickSessionView: View {
    /// Snapshotted at first construction, never re-read from the parent.
    /// `SessionBuilder.quickSession` shuffles and re-tiers on every call, and
    /// grading publishes `ProgressStore.seenItems`, which re-renders whichever
    /// parent (Home, the tour) built us. Holding the list as a plain `let`
    /// meant that re-render swapped a DIFFERENT question under the live index
    /// mid-answer, which read as "it changed the answer on me".
    @State private var items: [QuickItem]
    /// Set when the session is presented with no navigation stack of its own to
    /// escape through (the onboarding tour's fullScreenCover). Without it the
    /// player's FIRST question flow has no exit but finishing it, which is a
    /// trap, and a bad one right after the money page.
    private let onClose: (() -> Void)?
    /// Home's daily session spends the day's Get Started; the onboarding tour's
    /// demo run does not, so a brand-new player still finds a fresh Get Started
    /// waiting the first time they reach Home.
    private let purpose: QuickSessionPurpose

    init(items: [QuickItem], isDaily: Bool = true, onClose: (() -> Void)? = nil) {
        let saved = isDaily && onClose == nil ? OrdinaryRunStore.shared.run(for: SessionBuilder.sessionDrill.id) : nil
        _items = State(initialValue: saved?.items ?? items)
        _index = State(initialValue: saved?.index ?? 0)
        _score = State(initialValue: saved?.score ?? 0)
        _selection = State(initialValue: saved?.selection)
        _answers = State(initialValue: saved?.answers ?? [])
        _streak = State(initialValue: saved?.answers.reversed().prefix(while: { $0 }).count ?? 0)
        purpose = .quickSession(isDaily: isDaily)
        self.onClose = onClose
    }

    /// Picks up a started round where it stopped: the challenge counts the
    /// first run, so leaving mid-way must neither lose answers nor offer a reset.
    init(monthlyRound round: ChallengeRound, resume: MonthlyChallengeProgress? = nil, onClose: (() -> Void)? = nil) {
        _items = State(initialValue: round.items)
        purpose = .monthlyChallenge(round)
        self.onClose = onClose
        if let resume, resume.answers.count < round.items.count {
            _index = State(initialValue: resume.answers.count)
            _answers = State(initialValue: resume.answers)
            _score = State(initialValue: resume.answers.filter { $0 }.count)
        }
    }

    init(gameNightPrep items: [QuickItem], onClose: (() -> Void)? = nil) {
        _items = State(initialValue: items)
        purpose = .gameNightPrep
        self.onClose = onClose
    }

    @EnvironmentObject private var progress: ProgressStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var monthlyStore = MonthlyChallengeStore.shared

    @State private var index = 0
    @State private var score = 0
    @State private var finished = false
    @State private var selection: Int?
    @State private var answers: [Bool] = []
    @State private var monthlyResult: MonthlyChallengeResult?

    @State private var confettiTrigger = 0
    @State private var confettiParticleCount = 30
    @State private var flashOpacity: Double = 0
    /// The correct answer row, published by `ChoiceList`. The celebration
    /// launches from there, not from the middle of the screen.
    @State private var answerRect: CGRect?

    @State private var streak = 0
    @State private var streakBannerText: String?
    @State private var streakBannerTrigger = 0

    private static let streakMilestones: Set<Int> = [3, 5, 10]

    var body: some View {
        if finished {
            completion
        } else if items.isEmpty {
            // Not a finished round. Falling through to the completion screen
            // banked a streak day, a session count and a rating ask for a
            // session that asked nothing.
            emptySession
        } else {
            drillBody.onAppear { saveRun() }
        }
    }

    private var emptySession: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 44))
                .foregroundStyle(Theme.inkTertiary)
            Text("Nothing to practice")
                .font(Theme.display(26))
                .foregroundStyle(Theme.ink)
            Text("No questions could be prepared for this session. Try again in a moment.")
                .font(.subheadline)
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Button {
                if let onClose { onClose() } else { dismiss() }
            } label: {
                Text("Back").primaryCTA()
            }
        }
        .padding()
        .frame(maxWidth: Theme.readableContentWidth)
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
        .background(Theme.background)
        .navigationTitle(purpose.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var completion: some View {
        if case .monthlyChallenge(let round) = purpose, let monthlyResult {
            MonthlyChallengeResultView(round: round, result: monthlyResult, recordsCompletion: true, onDone: onClose)
        } else {
            DrillCompleteView(drill: purpose.drill, score: score, total: items.count, onDone: onClose)
        }
    }

    private var item: QuickItem { items[index] }

    /// The monthly challenge keeps its plum through the run, the way a room
    /// keeps its accent, so the run still reads as the challenge.
    private var accent: Color {
        if case .monthlyChallenge = purpose { return Theme.plum }
        return Theme.jade
    }
    private var answered: Bool { selection != nil }

    /// Coaching for the specific wrong answer the player chose, when the
    /// content carries one.
    private var missNote: MissNote? {
        guard let selection, selection != item.answerIndex else { return nil }
        guard let reason = item.note(forPick: selection) else { return nil }
        return MissNote(pickedLabel: item.choices[selection], reason: reason)
    }

    private var requeued: Bool {
        guard let selection, selection != item.answerIndex else { return false }
        guard item.isReviewable, PracticeSkill.skill(forItemID: item.id) == nil else { return false }
        // The free challenge can close on a Mahj+ question; a free player's
        // sessions never bring those back, so don't promise it.
        return SubscriptionService.shared.isPro || !SessionBuilder.isMemberOnly(item.id)
    }

    private var drillBody: some View {
        VStack(spacing: 16) {
            ProgressView(value: Double(index), total: Double(items.count))
                .tint(accent)
            VStack(spacing: 12) {
                QuestionPager(
                    prompt: item.prompt,
                    tiles: item.tiles,
                    explanation: item.explanation,
                    answered: answered,
                    eyebrow: item.sourceLabel.uppercased(),
                    missNote: missNote,
                    requeued: requeued
                ) {
                    ChoiceList(labels: item.choices, selection: selection, answerIndex: item.answerIndex) { pick in
                        grade(pick)
                    }
                }
                footer
            }
            .id(item.id)
            .transition(.questionSlide(reduceMotion: reduceMotion))
        }
        .padding()
        .frame(maxWidth: Theme.readableContentWidth)
        .frame(maxWidth: .infinity)
        .background(Theme.background)
        .drillStage(answerRect: $answerRect)
        .overlay { Theme.bamGreen.opacity(flashOpacity).allowsHitTesting(false).ignoresSafeArea() }
        .overlay {
            ConfettiBurst(
                trigger: confettiTrigger,
                origin: .init(x: 0.5, y: 0.35),
                particleCount: confettiParticleCount,
                sourceRect: answerRect
            )
        }
        .overlay(alignment: .top) {
            if let streakBannerText {
                StreakBanner(text: streakBannerText)
                    .padding(.top, 6)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .navigationTitle(purpose.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let onClose {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { onClose() }
                        .foregroundStyle(Theme.inkSecondary)
                }
            }
        }
    }

    private var footer: some View {
        Group {
            if answered {
                Button {
                    advance()
                } label: {
                    Text(index + 1 < items.count ? String(localized: "Next") : String(localized: "Finish")).primaryCTA(color: accent)
                }
            } else {
                Text("\(index + 1) of \(items.count)")
                    .font(.caption)
                    .foregroundStyle(Theme.inkTertiary)
                    .frame(height: 54)
            }
        }
    }

    // MARK: - Grading

    private func saveRun() {
        guard case .quickSession(let daily) = purpose, daily, onClose == nil else { return }
        OrdinaryRunStore.shared.save(OrdinaryRun(drill: purpose.drill, items: items, index: index,
            score: score, selection: selection, answers: answers))
    }

    private func grade(_ pick: Int) {
        guard selection == nil else { return }
        defer { saveRun() }
        selection = pick
        let correct = pick == item.answerIndex
        answers.append(correct)
        if case .monthlyChallenge(let round) = purpose {
            let wasOpen = monthlyStore.result(for: round) == nil
            if let result = monthlyStore.recordAnswer(round: round, correct: correct, pick: pick) {
                monthlyResult = result
                // The last answer banks the run, so it banks the session and
                // the streak day too. Crediting them on the result screen
                // lost both whenever the app closed before Finish.
                if wasOpen { progress.recordSession(drillID: MonthlyChallengeContent.drill.id) }
            }
        }
        if item.isReviewable {
            progress.recordItem(id: item.id, correct: correct)
        }
        // Also feeds the spaced-repetition queue and the accuracy stats. The
        // daily mix is where most answers happen, so leaving it out would mean
        // Fix My Mistakes had almost nothing to work with.
        PracticeRecordStore.shared.record(
            itemID: item.trackingID,
            roomID: item.roomID,
            correct: correct,
            isReviewable: item.isReviewable
        )
        if correct {
            score += 1
            streak += 1
            landCorrect()
        } else {
            streak = 0
            Haptics.wrongAnswer()
            SoundPlayer.play(.miss)
        }
    }

    /// The dopamine landing: confetti + haptic + sound every time, escalating
    /// with a full-screen glow flash and a stronger haptic + banner at streak
    /// milestones. A miss keeps the existing gentle feedback in `grade`.
    private func landCorrect() {
        confettiParticleCount = particleCount(forStreak: streak)
        confettiTrigger += 1
        Haptics.correctAnswer()
        SoundPlayer.play(.success)

        if !reduceMotion {
            flashOpacity = 0.14
            withAnimation(.easeOut(duration: 0.5)) { flashOpacity = 0 }
        }

        guard Self.streakMilestones.contains(streak) else { return }
        Haptics.impact(.rigid, intensity: 1.0)
        announceStreak(streak)
    }

    private func particleCount(forStreak streak: Int) -> Int {
        switch streak {
        case 10...: return 90
        case 5..<10: return 60
        case 3..<5: return 44
        default: return 28
        }
    }

    private func announceStreak(_ streak: Int) {
        streakBannerTrigger += 1
        let trigger = streakBannerTrigger
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            streakBannerText = String(localized: "\(streak) in a row!")
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            guard trigger == streakBannerTrigger else { return }
            withAnimation(.easeOut(duration: 0.3)) { streakBannerText = nil }
        }
    }

    private func finishSession() {
        OrdinaryRunStore.shared.clear(purpose.drill.id)
        switch purpose {
        case .quickSession(let isDaily):
            if isDaily { progress.markQuickSessionCompleted() }
        case .monthlyChallenge(let round):
            monthlyResult = monthlyResult ?? monthlyStore.record(round: round, answers: answers)
        case .gameNightPrep:
            break
        }
        withAnimation(.easeInOut(duration: 0.3)) { finished = true }
    }

    private func advance() {
        guard answered else { return }
        if index + 1 < items.count {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                selection = nil
                index += 1
                saveRun()
            }
        } else {
            finishSession()
        }
    }
}

/// Brief celebratory pill for a consecutive-correct milestone (3/5/10 in a row).
private struct StreakBanner: View {
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
            Text(text)
                .font(.subheadline.weight(.heavy))
        }
        .foregroundStyle(Theme.onFill)
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(Theme.coral, in: Capsule())
        .shadow(color: Theme.coral.opacity(0.4), radius: 10, y: 4)
    }
}
