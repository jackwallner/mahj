import SwiftUI

/// Play a Hand: commit to a section, then draw and discard twelve times while
/// a coach grades every throw.
///
/// The whole rest of the app asks "what is this?". This asks "what would you
/// do?", which is the skill a player actually needs at a table and the one
/// nothing else here tests. There are no opponents on purpose (see
/// `HandPlayEngine`), so nothing on this screen can be unfair: the wall is
/// random, your rack is yours, and the coach's answer is arithmetic you can
/// check.
struct HandPlayView: View {
    @EnvironmentObject private var progress: ProgressStore
    @EnvironmentObject private var subscriptions: SubscriptionService
    @StateObject private var handPlay = HandPlayStore.shared
    @StateObject private var records = PracticeRecordStore.shared
    @Environment(\.dismiss) private var dismiss

    enum Phase: Equatable {
        case choosing
        /// Target picked, coach's read shown, not yet dealt into play.
        case committed
        case playing
        case finished
    }

    @State private var phase: Phase = .choosing
    @State private var rack: [Tile] = []
    @State private var wall: [Tile] = []
    @State private var wallIndex = 0
    @State private var target: HandCategory?
    @State private var turn = 0
    @State private var drawn: Tile?
    @State private var grade: Grade?
    @State private var cleanDiscards = 0
    @State private var verdict: HandPlayEngine.Verdict?
    @State private var confettiTrigger = 0
    @State private var showPaywall = false

    /// The result of one throw, held on screen until the player advances.
    struct Grade: Equatable {
        let discard: Tile
        let wasBest: Bool
        let note: String
    }

    var body: some View {
        Group {
            switch phase {
            case .choosing, .committed: setupScreen
            case .playing: playScreen
            case .finished: verdictScreen
            }
        }
        .background(Theme.background)
        .navigationTitle("Play a Hand")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) { PaywallView(source: "mahj_hand_play") }
        .overlay { ConfettiBurst(trigger: confettiTrigger, origin: .init(x: 0.5, y: 0.4)) }
        .task { dealIfNeeded() }
    }

    // MARK: - Setup

    private func dealIfNeeded() {
        guard rack.isEmpty else { return }
        let deal = HandPlayEngine.deal()
        rack = deal.rack
        wall = deal.wall
    }

    private var setupScreen: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 6) {
                    Text("Your deal")
                        .font(Theme.display(24))
                        .foregroundStyle(Theme.ink)
                    Text("Thirteen tiles, straight off the wall. Pick the family you are going to chase, then everything you keep should serve it.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.inkSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 10)

                TileRackView(tiles: rack, tileWidth: 40)

                if phase == .committed, let target {
                    coachRead(for: target)
                } else {
                    targetChoices
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 28)
            .frame(maxWidth: Theme.readableContentWidth)
            .frame(maxWidth: .infinity)
        }
    }

    private var targetChoices: some View {
        VStack(spacing: 10) {
            Text("COMMIT TO A SECTION")
                .font(.caption.weight(.heavy))
                .kerning(1.3)
                .foregroundStyle(Theme.inkSecondary)
                .padding(.top, 6)
            ForEach(HandPlayEngine.playableTargets) { category in
                Button {
                    choose(category)
                } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(category.displayName)
                                .font(.headline)
                                .foregroundStyle(Theme.ink)
                            Text(category.howToSpot)
                                .font(.caption)
                                .foregroundStyle(Theme.inkSecondary)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 4)
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Theme.inkTertiary)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity)
                    .themedCard(corner: 16)
                }
                .buttonStyle(PressableCardStyle())
            }
        }
    }

    /// What the coach would have committed to, and why. Shown only after the
    /// player has picked, so it teaches rather than answers: a different pick
    /// is not marked wrong, and the hand is then graded against THEIR choice,
    /// because that is the hand they are now playing.
    private func coachRead(for chosen: HandCategory) -> some View {
        let ranked = HandPlayEngine.rankedTargets(for: rack)
        let coachPick = ranked.first?.target
        let agrees = coachPick == chosen
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: agrees ? "checkmark.seal.fill" : "graduationcap.fill")
                    .foregroundStyle(agrees ? Theme.bamGreen : Theme.gold)
                Text(agrees ? "The coach agrees" : "The coach reads it differently")
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
            }
            Text(agrees
                 ? "\(chosen.displayName) is where most of this rack already points. Play it out."
                 : "The coach would have started \(coachPick?.displayName ?? chosen.displayName) with this deal. You are not wrong to try \(chosen.displayName), and a hand you have committed to beats a hand you keep changing your mind about, so that is what these twelve turns will be graded against.")
                .font(.subheadline)
                .foregroundStyle(Theme.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(ranked, id: \.target) { entry in
                    let fitting = HandPlayEngine.fittingTiles(in: rack, target: entry.target)
                    HStack {
                        Text(entry.target.shortName)
                            .font(.footnote.weight(entry.target == chosen ? .bold : .regular))
                            .foregroundStyle(entry.target == chosen ? Theme.ink : Theme.inkSecondary)
                        Spacer()
                        Text("\(fitting) tile\(fitting == 1 ? "" : "s") fit")
                            .font(.caption)
                            .foregroundStyle(Theme.inkTertiary)
                            .monospacedDigit()
                    }
                    .padding(.vertical, 3)
                }
                // The order is by strength, not by raw count, and those are
                // genuinely different: three of a kind is most of a group,
                // three loose tiles are three separate problems. Saying so
                // stops the list looking like it sorted itself wrong.
                Text("Ordered by how strong the rack is, not by the raw count: a pair or a pung is worth more than the same tiles scattered.")
                    .font(.caption2)
                    .foregroundStyle(Theme.inkTertiary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            }
            .padding(12)
            .background(Theme.well, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            Button {
                startPlaying()
            } label: {
                Text("Play it out").primaryCTA()
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .themedCard(corner: 18)
    }

    private func choose(_ category: HandCategory) {
        Haptics.impact(.light)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            target = category
            phase = .committed
        }
    }

    private func startPlaying() {
        handPlay.recordStart(isMember: subscriptions.isPro)
        withAnimation(.easeInOut(duration: 0.25)) { phase = .playing }
        draw()
    }

    // MARK: - Playing

    private var playScreen: some View {
        VStack(spacing: 14) {
            statusBar
            CenteringScrollView {
                VStack(spacing: 16) {
                    if let drawn {
                        Text(grade == nil
                             ? "You drew the \(drawn.spokenName). What goes?"
                             : "You threw the \(grade?.discard.spokenName ?? "").")
                            .font(Theme.display(21))
                            .foregroundStyle(Theme.ink)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    TileRackView(
                        tiles: rack,
                        tileWidth: 40,
                        highlightedIndices: highlightedIndices,
                        onTap: { index in throwTile(at: index) }
                    )
                    if let grade {
                        gradeCard(grade)
                    } else {
                        Text("Tap the tile you want to throw")
                            .font(.caption)
                            .foregroundStyle(Theme.inkTertiary)
                    }
                }
            }
            if grade != nil {
                Button {
                    advance()
                } label: {
                    Text(turn >= HandPlayEngine.turnCount ? "See how you did" : "Next turn").primaryCTA()
                }
            }
        }
        .padding()
        .frame(maxWidth: Theme.readableContentWidth)
        .frame(maxWidth: .infinity)
    }

    /// Before the throw, the tile just drawn is marked so the player can find
    /// it among thirteen others. After it, nothing is marked: the rack has
    /// already changed and a leftover highlight would point at the wrong tile.
    private var highlightedIndices: Set<Int> {
        guard grade == nil, let drawn, let index = rack.firstIndex(of: drawn) else { return [] }
        return [index]
    }

    private var statusBar: some View {
        HStack(spacing: 10) {
            Text("Turn \(min(turn, HandPlayEngine.turnCount)) of \(HandPlayEngine.turnCount)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.inkSecondary)
                .monospacedDigit()
            Spacer()
            if let target {
                HStack(spacing: 5) {
                    Image(systemName: "target")
                        .font(.caption2)
                    Text(target.shortName)
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(Theme.jade)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(Theme.jade.opacity(0.12), in: Capsule())
                Text("\(fittingCount) fit")
                    .accessibilityLabel("\(fittingCount) tiles fit the section")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.inkSecondary)
                    .monospacedDigit()
            }
        }
    }

    /// Tiles that FIT, not tiles already grouped. The choose screen and the
    /// verdict both count this way, and a chip that reads "0 working" while
    /// the player is visibly holding three even tiles looks like a bug.
    private var fittingCount: Int {
        guard let target else { return 0 }
        return HandPlayEngine.fittingTiles(in: rack, target: target)
    }

    private func gradeCard(_ grade: Grade) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: grade.wasBest ? "checkmark.circle.fill" : "lightbulb.fill")
                .foregroundStyle(grade.wasBest ? Theme.bamGreen : Theme.gold)
            Text(grade.note)
                .font(.subheadline)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            (grade.wasBest ? Theme.bamGreen : Theme.gold).opacity(0.12),
            in: RoundedRectangle(cornerRadius: 14)
        )
        .transition(.scale(scale: 0.96).combined(with: .opacity))
    }

    private func draw() {
        guard wallIndex < wall.count else {
            finish()
            return
        }
        let tile = wall[wallIndex]
        wallIndex += 1
        turn += 1
        drawn = tile
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            rack = (rack + [tile]).racked
        }
    }

    private func throwTile(at index: Int) {
        guard grade == nil, let target, rack.indices.contains(index) else { return }
        let tile = rack[index]
        let best = HandPlayEngine.bestDiscards(from: rack, target: target)
        let wasBest = best.contains(tile)
        let note = HandPlayEngine.coachNote(for: tile, rack: rack, target: target, wasBest: wasBest)

        var updated = rack
        updated.remove(at: index)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            rack = updated
            grade = Grade(discard: tile, wasBest: wasBest, note: note)
        }
        if wasBest {
            cleanDiscards += 1
            Haptics.correctAnswer()
            SoundPlayer.play(.success)
        } else {
            Haptics.wrongAnswer()
            SoundPlayer.play(.miss)
        }
        // One rollup row for the whole mode, never one row per throw: the ids
        // are unique per turn and would otherwise grow without bound.
        records.record(
            itemID: PracticeSkill.handPlay.itemPrefix + UUID().uuidString,
            roomID: PracticeSkill.handPlay.roomID,
            correct: wasBest,
            isReviewable: false
        )
    }

    private func advance() {
        withAnimation(.easeInOut(duration: 0.2)) { grade = nil }
        if turn >= HandPlayEngine.turnCount {
            finish()
        } else {
            draw()
        }
    }

    private func finish() {
        guard let target else { return }
        let result = HandPlayEngine.verdict(
            rack: rack,
            target: target,
            cleanDiscards: cleanDiscards,
            discards: turn
        )
        verdict = result
        handPlay.recordVerdict(stars: result.stars)
        progress.recordSession(drillID: "hand-play")
        if result.stars >= 2 {
            confettiTrigger += 1
            Haptics.correctAnswer()
            SoundPlayer.play(.success)
        }
        withAnimation(.easeInOut(duration: 0.3)) { phase = .finished }
    }

    // MARK: - Verdict

    @ViewBuilder
    private var verdictScreen: some View {
        if let verdict {
            ScrollView {
                VStack(spacing: 16) {
                    HStack(spacing: 6) {
                        ForEach(0..<3, id: \.self) { index in
                            Image(systemName: index < verdict.stars ? "star.fill" : "star")
                                .font(.title2)
                                .foregroundStyle(index < verdict.stars ? Theme.gold : Theme.inkTertiary.opacity(0.4))
                        }
                    }
                    .padding(.top, 18)

                    Text(verdict.headline)
                        .font(Theme.display(26))
                        .foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 0) {
                        metric("\(verdict.fitting)/\(verdict.total)", "tiles fit", Theme.jade)
                        Divider().frame(height: 34)
                        metric("\(verdict.cleanDiscards)/\(verdict.discards)", "clean throws", Theme.coral)
                    }
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .themedCard()

                    Text(verdict.body)
                        .font(.subheadline)
                        .foregroundStyle(Theme.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("YOUR FINAL RACK")
                            .font(.caption2.weight(.heavy))
                            .kerning(1.2)
                            .foregroundStyle(Theme.inkTertiary)
                        TileRackView(tiles: rack, tileWidth: 34)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if canPlayAgain {
                        Button { playAgain() } label: {
                            Text("Deal another hand").primaryCTA()
                        }
                    } else {
                        upsell
                    }
                    Button("Done") { dismiss() }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.inkSecondary)
                }
                .padding(.horizontal)
                .padding(.bottom, 28)
                .frame(maxWidth: Theme.readableContentWidth)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func metric(_ value: String, _ caption: String, _ color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(Theme.display(24))
                .foregroundStyle(color)
                .monospacedDigit()
            Text(caption)
                .font(.caption)
                .foregroundStyle(Theme.inkSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var canPlayAgain: Bool {
        handPlay.canPlay(isMember: subscriptions.isPro)
    }

    /// The free hand is spent. This is the one moment the upsell is actually
    /// welcome: the player has just finished a whole hand and knows exactly
    /// what the next one is worth.
    private var upsell: some View {
        Button {
            showPaywall = true
        } label: {
            VStack(spacing: 6) {
                Text("That was today's free hand")
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                Text("\(Membership.name) deals as many as you want, whenever you want them.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(Theme.gold.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Theme.gold.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(PressableCardStyle())
    }

    private func playAgain() {
        let deal = HandPlayEngine.deal()
        rack = deal.rack
        wall = deal.wall
        wallIndex = 0
        turn = 0
        drawn = nil
        grade = nil
        cleanDiscards = 0
        verdict = nil
        target = nil
        withAnimation(.easeInOut(duration: 0.25)) { phase = .choosing }
    }
}
