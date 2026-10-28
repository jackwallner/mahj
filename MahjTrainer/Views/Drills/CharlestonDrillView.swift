import SwiftUI

struct CharlestonDrillView: View {
    let drill: Drill
    let scenarios: [CharlestonScenario]

    init(drill: Drill, scenarios: [CharlestonScenario]) {
        self.drill = drill
        self.scenarios = scenarios
        let saved = OrdinaryRunStore.shared.run(for: drill.id)
        _answers = State(initialValue: saved?.answers ?? [])
        _index = State(initialValue: saved?.index ?? 0)
        _score = State(initialValue: saved?.score ?? 0)
        _selected = State(initialValue: saved?.selected ?? [])
        _submitted = State(initialValue: saved?.submitted ?? false)
    }

    @EnvironmentObject private var progress: ProgressStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var index = 0
    @State private var selected: Set<Int> = []
    @State private var submitted = false
    @State private var score = 0
    @State private var answers: [Bool] = []
    @State private var finished = false
    @State private var confettiTrigger = 0
    @State private var shineTrigger = 0

    var body: some View {
        if finished {
            DrillCompleteView(drill: drill, score: score, total: scenarios.count * 3)
        } else {
            drillBody
        }
    }

    private var scenario: CharlestonScenario { scenarios[index] }
    /// The deal is shown racked. We grade by tile multiset.
    private var rackedDeal: [Tile] { scenario.deal.racked }

    private var drillBody: some View {
        VStack(spacing: 16) {
            ProgressView(value: Double(index), total: Double(scenarios.count))
                .tint(Theme.jade)
            CenteringScrollView {
                VStack(spacing: 18) {
                    Text(scenario.situation)
                        .font(Theme.display(20, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                    TileRackView(
                        tiles: rackedDeal,
                        tileWidth: 44,
                        highlightedIndices: selected,
                        onTap: { index in toggle(index) }
                    )
                    .padding(.vertical, 6)
                    if submitted {
                        coachCard
                            .shine(trigger: shineTrigger, corner: 16)
                            .winGlow(Theme.gold, active: matchCount == 3)
                            // Arrives once the rack has moved up, and the
                            // count leaves at once: the card used to appear
                            // under tiles still sliding across it (2026-10-19
                            // frame capture).
                            .transition(reduceMotion ? .identity : .asymmetric(
                                insertion: .scale(scale: 0.94).combined(with: .opacity)
                                    .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.2)),
                                removal: .identity
                            ))
                    } else {
                        Text("Selected \(selected.count) of 3")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .transition(.identity)
                    }
                }
            }
            footer
        }
        .padding()
        .frame(maxWidth: Theme.readableContentWidth)
        .frame(maxWidth: .infinity)
        .background(Theme.background)
        .overlay { ConfettiBurst(trigger: confettiTrigger, origin: .init(x: 0.5, y: 0.35)) }
        .navigationTitle(drill.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var coachCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: matchCount == 3 ? "star.fill" : "graduationcap.fill")
                    .foregroundStyle(Theme.gold)
                Text(headline)
                    .font(.headline)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Coach would pass:")
                    .font(.subheadline.weight(.semibold))
                HStack(spacing: 6) {
                    ForEach(Array(scenario.recommendedPass.enumerated()), id: \.offset) { _, tile in
                        TileView(tile: tile, width: 40)
                    }
                }
            }
            Text(scenario.reasoning)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(Theme.gold)
                Text(scenario.tip)
                    .font(.footnote.weight(.medium))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .themedCard(corner: 16)
    }

    private var headline: String {
        switch matchCount {
        case 3: return String(localized: "Perfect pass! 3 of 3")
        case 2: return String(localized: "Close! 2 of 3 match")
        case 1: return String(localized: "1 of 3 matched the coach")
        default: return String(localized: "The coach saw it differently")
        }
    }

    /// Grade by tile multiset so equivalent duplicates count as matches.
    private var matchCount: Int {
        var pool = scenario.recommendedPass
        var matches = 0
        for i in selected {
            if let hit = pool.firstIndex(of: rackedDeal[i]) {
                pool.remove(at: hit)
                matches += 1
            }
        }
        return matches
    }

    private var footer: some View {
        Group {
            if submitted {
                Button {
                    advance()
                } label: {
                    Text(index + 1 < scenarios.count ? String(localized: "Next Deal") : String(localized: "Finish")).primaryCTA()
                }
            } else {
                Button {
                    submit()
                } label: {
                    Text("Pass These 3").primaryCTA()
                }
                .disabled(selected.count != 3)
                .opacity(selected.count == 3 ? 1 : 0.4)
            }
        }
    }

    private func toggle(_ tileIndex: Int) {
        guard !submitted else { return }
        if selected.contains(tileIndex) {
            selected.remove(tileIndex)
        } else if selected.count < 3 {
            // Jokers may never be passed. Enforce the real rule in the drill.
            if case .joker = rackedDeal[tileIndex] { return }
            selected.insert(tileIndex)
        }
        saveRun()
    }

    private func saveRun() {
        OrdinaryRunStore.shared.save(OrdinaryRun(drill: drill, index: index, score: score, answers: answers, selected: selected, submitted: submitted))
    }

    private func submit() {
        guard !submitted, selected.count == 3 else { return }
        defer { saveRun() }
        withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8)) { submitted = true }
        answers.append(matchCount >= 2)
        score += matchCount
        progress.recordItem(id: scenario.id, correct: matchCount >= 2)
        PracticeRecordStore.shared.record(itemID: scenario.id, roomID: DrillLibrary.roomID(forDrillID: drill.id), correct: matchCount >= 2)
        if matchCount == 3 {
            confettiTrigger += 1
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 350_000_000)
                shineTrigger += 1
            }
            Haptics.correctAnswer()
            SoundPlayer.play(.success)
        } else if matchCount == 2 {
            // Two of three is partial credit: the bright chime, without the
            // full "you nailed it" landing.
            Haptics.success()
            SoundPlayer.play(.success)
        } else {
            Haptics.wrongAnswer()
            SoundPlayer.play(.miss)
        }
    }

    private func advance() {
        guard DrillNext.allowed(answered: submitted, finished: finished) else { return }
        if index + 1 < scenarios.count {
            selected = []
            submitted = false
            index += 1
            saveRun()
        } else {
            OrdinaryRunStore.shared.clear(drill.id)
            finished = true
        }
    }
}
