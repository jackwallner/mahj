import SwiftUI

/// Flashcards as a swipeable deck. The grammar: tap flips the card to reveal
/// the answer; only a flipped card can be swiped. Right = "got it" (card
/// leaves the deck), left = "again" (card returns at the back). Before the
/// flip a horizontal drag rubber-bands, so the reveal always comes first.
/// Cards with a `CardChoice` add a self-test: pick Keep/Throw on the front,
/// and the flip grades you.
struct FlashcardDrillView: View {
    let drill: Drill
    let cards: [Flashcard]
    var accent: Color = Theme.jade

    init(drill: Drill, cards: [Flashcard], accent: Color = Theme.jade) {
        self.drill = drill
        self.cards = cards
        self.accent = accent
        let saved = OrdinaryRunStore.shared.run(for: drill.id)
        _answers = State(initialValue: saved?.answers ?? [])
        _queue = State(initialValue: saved?.queue ?? cards)
        _isFlipped = State(initialValue: saved?.flipped ?? false)
        _choicePick = State(initialValue: saved?.selection)
        _pendingAnswer = State(initialValue: saved?.pendingAnswer)
        _lastSwipe = State(initialValue: saved?.lastSwipe)
    }

    @EnvironmentObject private var progress: ProgressStore
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var queue: [Flashcard] = []
    @State private var isFlipped = false
    @State private var drag: CGSize = .zero
    @State private var isFlinging = false
    @State private var crossedThreshold = false
    @State private var lastSwipe: SwipeRecord?
    @State private var pendingAnswer: AnswerSnapshot?
    @State private var answers: [Bool] = []
    @State private var finished = false
    @State private var choicePick: Int?
    @State private var confettiTrigger = 0
    /// Fades the departing card (and the KNEW IT / AGAIN stamp riding on it)
    /// out with the throw. Without it the card is simply yanked from the queue
    /// at commit and the verdict stamp blinks out of existence mid-flight.
    @State private var flingOpacity: Double = 1

    /// One-time teaching nudge after the first-ever flip.
    @AppStorage("mahj.hasSwipedDeck") private var hasSwipedDeck = false
    @State private var didHint = false

    private typealias SwipeRecord = OrdinaryRun.SwipeRecord
    private typealias AnswerSnapshot = OrdinaryRun.AnswerSnapshot

    private func snapshotAnswer(for card: Flashcard) -> AnswerSnapshot {
        AnswerSnapshot(
            progress: progress.snapshotItem(id: card.id),
            practice: PracticeRecordStore.shared.snapshotAnswer(itemID: card.id)
        )
    }

    var body: some View {
        if finished {
            DrillCompleteView(drill: drill, score: nil, total: cards.count)
        } else {
            drillBody
                .onAppear { saveRun() }
                .onChange(of: isFlipped) { _, _ in saveRun() }
                .onChange(of: answers) { _, _ in saveRun() }
                .onChange(of: choicePick) { _, _ in saveRun() }
                .onChange(of: queue.map(\.id)) { _, _ in saveRun() }
        }
    }

    private func saveRun() {
        guard !finished else { return }
        OrdinaryRunStore.shared.save(OrdinaryRun(drill: drill, score: answers.filter { $0 }.count, selection: choicePick, answers: answers, queue: queue, flipped: isFlipped, pendingAnswer: pendingAnswer, lastSwipe: lastSwipe))
    }

    private var mastered: Int { cards.count - queue.count }

    private var drillBody: some View {
        VStack(spacing: 14) {
            header
            GeometryReader { geo in
                // A card should still look like a card. Unbounded, the deck
                // stretches to whatever height it is given, which on a 13-inch
                // iPad is a playing card two feet tall with its text marooned
                // in the middle. Cap the height to a card-ish ratio and centre
                // the deck in what is left; the capped size is also what the
                // fling distance is measured against.
                // 520pt keeps the card close to the proportions it has on a
                // phone, where the face was designed. Widening it to the full
                // readable width just spreads the same few words thinner.
                // At accessibility sizes the words need the room more than
                // the card needs its proportions, so it takes the full width.
                let width = dynamicTypeSize.isAccessibilitySize ? geo.size.width : min(geo.size.width, 520)
                let capped = CGSize(
                    width: width,
                    height: min(geo.size.height, width * 1.5)
                )
                deck(size: capped)
                    .frame(width: capped.width, height: capped.height)
                    .frame(width: geo.size.width, height: geo.size.height)
            }
            .padding(.horizontal, 4)
        }
        .padding()
        .frame(maxWidth: Theme.readableContentWidth)
        .frame(maxWidth: .infinity)
        .background(Theme.background)
        .overlay { ConfettiBurst(trigger: confettiTrigger, origin: .init(x: 0.5, y: 0.42)) }
        .navigationTitle(drill.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if lastSwipe != nil {
                    Button {
                        undo()
                    } label: {
                        Image(systemName: "arrow.uturn.backward")
                    }
                    .accessibilityLabel("Undo last answer")
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.well)
                    Capsule()
                        .fill(accent)
                        .frame(width: geo.size.width * CGFloat(mastered) / CGFloat(max(cards.count, 1)))
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: mastered)
                }
            }
            .frame(height: 8)
            Text("\(mastered) of \(cards.count) down")
                .font(.footnote.weight(.medium))
                .foregroundStyle(Theme.inkSecondary)
                .monospacedDigit()
        }
    }

    // MARK: - Deck

    @ViewBuilder
    private func deck(size: CGSize) -> some View {
        let visible = Array(queue.prefix(3).enumerated())
        ZStack {
            ForEach(visible.reversed(), id: \.element.id) { slot, card in
                FlipCardFace(
                    card: card,
                    isFlipped: slot == 0 && isFlipped,
                    accent: accent,
                    choicePick: slot == 0 ? choicePick : nil,
                    onChoose: slot == 0 ? { choose($0, card: card) } : nil,
                    onAdvance: slot == 0 && choicePick != nil
                        ? { fling(direction: 1, size: size) }
                        : nil
                )
                .scaleEffect(scale(forSlot: slot))
                .offset(y: yOffset(forSlot: slot))
                .offset(slot == 0 ? effectiveDrag : .zero)
                .rotationEffect(slot == 0 ? topRotation : .zero, anchor: .bottom)
                .overlay { if slot == 0 { verdictStamps } }
                .opacity(slot == 0 ? flingOpacity : 1)
                .zIndex(Double(3 - slot))
                .allowsHitTesting(slot == 0)
                .gesture(dragGesture(size: size))
                .accessibilityAddTraits(.isButton)
                .accessibilityHint(swipeAccessibilityHint)
                // The deck is gestures; VoiceOver and Switch Control get the
                // same moves as named actions. Activating flips, and a
                // revealed plain card offers Knew It and Again.
                .accessibilityAction { if slot == 0 { flip() } }
                .accessibilityActions {
                    if slot == 0, isFlipped, !choiceAnswered, !isFlinging {
                        Button("Knew It") { fling(direction: 1, size: size) }
                        Button("Again") { fling(direction: -1, size: size) }
                    }
                }
                // Only the top card can be flipped or flung. The two behind it
                // are scenery: left in the tree they give VoiceOver two cards
                // that answer nothing, which reads as a broken deck.
                .accessibilityHidden(slot != 0)
                .environment(\.isDeckScenery, slot != 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Room below the front card so the stacked edges peek.
        .padding(.bottom, 26)
    }

    /// Pre-flip, horizontal pulls rubber-band: the card answers the finger but
    /// makes it obvious it won't leave until it's been flipped.
    private var effectiveDrag: CGSize {
        guard !isFlipped, !isFlinging else { return drag }
        return CGSize(width: drag.width * 0.16, height: drag.height * 0.10)
    }

    /// Once a choice card is answered, the pick is the grade. The card holds
    /// on that result until the player taps Next.
    private var choiceAnswered: Bool {
        queue.first?.choice != nil && choicePick != nil
    }

    private var swipeAccessibilityHint: String {
        guard isFlipped else { return String(localized: "Reveals the answer") }
        return choiceAnswered
            ? String(localized: "Tap Next to continue")
            : String(localized: "Swipe right if you knew it, left to see it again, or use the Knew It and Again actions")
    }

    /// KNEW IT / AGAIN stamps fade in with the drag so the swipe directions
    /// carry their meaning on the card itself, using the same words as the hint and
    /// the quick session buttons, one grading vocabulary everywhere.
    private var verdictStamps: some View {
        ZStack {
            if !choiceAnswered {
                stamp(String(localized: "KNEW IT"), color: Theme.jade, angle: -12)
                    .opacity(isFlipped ? stampOpacity(forDirection: 1) : 0)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                stamp(String(localized: "AGAIN"), color: Theme.coral, angle: 12)
                    .opacity(isFlipped ? stampOpacity(forDirection: -1) : 0)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }
        }
        .padding(22)
        .allowsHitTesting(false)
    }

    private func stamp(_ text: String, color: Color, angle: Double) -> some View {
        Text(text)
            .font(Theme.display(24, weight: .black))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(color, lineWidth: 3))
            .rotationEffect(.degrees(angle))
    }

    private func stampOpacity(forDirection direction: CGFloat) -> Double {
        let travel = drag.width * direction
        return Double(min(1, max(0, travel / 80)))
    }

    // MARK: - Stack geometry (deck physics shared with the fleet's decks)

    private func dismissDistance(_ size: CGSize) -> CGFloat {
        max(90, size.width * 0.30)
    }

    private var progress01: CGFloat {
        guard isFlipped else { return 0 }
        return min(1, abs(drag.width) / 110)
    }

    private func restingScale(_ slot: Int) -> CGFloat { 1 - CGFloat(slot) * 0.04 }
    private func restingY(_ slot: Int) -> CGFloat { CGFloat(slot) * 24 }

    private func scale(forSlot slot: Int) -> CGFloat {
        guard slot > 0 else { return 1 }
        return restingScale(slot) + (restingScale(slot - 1) - restingScale(slot)) * progress01
    }

    private func yOffset(forSlot slot: Int) -> CGFloat {
        guard slot > 0 else { return 0 }
        return restingY(slot) + (restingY(slot - 1) - restingY(slot)) * progress01
    }

    private var topRotation: Angle {
        .degrees(Double(max(-12, min(12, effectiveDrag.width / 14))))
    }

    // MARK: - Choice self-test

    private func choose(_ index: Int, card: Flashcard) {
        guard let choice = card.choice, choicePick == nil, !isFlipped, !isFlinging else { return }
        // Once this card is graded, undo must not rewind a different card.
        lastSwipe = nil
        pendingAnswer = snapshotAnswer(for: card)
        choicePick = index
        let correct = index == choice.answerIndex
        answers.append(correct)
        progress.recordItem(id: card.id, correct: correct)
        PracticeRecordStore.shared.record(itemID: card.id, roomID: DrillLibrary.roomID(forDrillID: drill.id), correct: correct)
        if correct {
            confettiTrigger += 1
            Haptics.correctAnswer()
            SoundPlayer.play(.success)
        } else {
            Haptics.wrongAnswer()
            SoundPlayer.play(.miss)
        }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) {
            isFlipped = true
        }
        maybeHintSwipe()
    }

    // MARK: - Gestures

    private func flip() {
        guard !isFlinging, !choiceAnswered else { return }
        Haptics.impact(.soft, intensity: 0.5)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            isFlipped.toggle()
        }
        if isFlipped { maybeHintSwipe() }
    }

    private func dragGesture(size: CGSize) -> some Gesture {
        // minimumDistance 0 so the gesture also owns taps: a release that
        // barely moved flips the card (see onEnded). A separate TapGesture
        // loses the arbitration race against this drag and never fires.
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard !isFlinging else { return }
                drag = value.translation
                guard isFlipped else { return }
                let past = abs(value.translation.width) > dismissDistance(size)
                if past != crossedThreshold {
                    crossedThreshold = past
                    if past { Haptics.impact(.soft, intensity: 0.6) }
                }
            }
            .onEnded { value in
                guard !isFlinging else { return }
                crossedThreshold = false
                // A release that barely moved is a tap; the drag gesture wins
                // the race against onTapGesture, so honor the flip here too.
                if abs(value.translation.width) < 10, abs(value.translation.height) < 10 {
                    drag = .zero
                    flip()
                    return
                }
                guard isFlipped else {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                        drag = .zero
                    }
                    return
                }
                guard !choiceAnswered else {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                        drag = .zero
                    }
                    return
                }
                let dx = value.translation.width
                let flung = abs(dx) > dismissDistance(size)
                    || abs(value.predictedEndTranslation.width) > size.width * 0.75
                if flung {
                    fling(direction: dx >= 0 ? 1 : -1, size: size)
                } else {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                        drag = .zero
                    }
                }
            }
    }

    /// Throw the card off, then commit the grade with animation suppressed.
    /// the risen card behind is already in place, so nothing jumps. The card
    /// fades as it goes, so the verdict stamp leaves with it instead of being
    /// cut off the instant the queue drops the card.
    private func fling(direction: CGFloat, size: CGSize) {
        isFlinging = true
        hasSwipedDeck = true
        Haptics.impact(.rigid, intensity: 0.7)
        let exit = CGSize(width: direction * size.width * 1.5, height: drag.height * 1.1)
        withAnimation(.easeIn(duration: 0.34)) {
            drag = exit
            flingOpacity = 0
        } completion: {
            var t = Transaction()
            t.disablesAnimations = true
            withTransaction(t) {
                commit(gotIt: direction > 0)
                drag = .zero
                flingOpacity = 1
                isFlinging = false
                isFlipped = false
            }
        }
    }

    private func commit(gotIt: Bool) {
        guard let card = queue.first else { return }
        // Choice cards were graded at pick time; the swipe only advances, and
        // the graded answer (not the swipe direction) decides whether the
        // card comes back. Plain cards grade by swipe.
        let knewIt: Bool
        let answer = pendingAnswer ?? snapshotAnswer(for: card)
        if let choice = card.choice, let pick = choicePick {
            knewIt = pick == choice.answerIndex
        } else {
            knewIt = gotIt
            answers.append(gotIt)
            progress.recordItem(id: card.id, correct: gotIt)
            PracticeRecordStore.shared.record(itemID: card.id, roomID: DrillLibrary.roomID(forDrillID: drill.id), correct: gotIt)
        }
        lastSwipe = SwipeRecord(card: card, gotIt: knewIt, answer: answer)
        pendingAnswer = nil
        choicePick = nil
        queue.removeFirst()
        if !knewIt {
            queue.append(card)
        }
        if queue.isEmpty {
            OrdinaryRunStore.shared.clear(drill.id)
            Haptics.success()
            withAnimation(.easeInOut(duration: 0.3)) { finished = true }
        }
    }

    private func undo() {
        guard let record = lastSwipe, !isFlinging else { return }
        Haptics.impact(.light)
        if !answers.isEmpty { answers.removeLast() }
        progress.restoreItem(record.answer.progress)
        PracticeRecordStore.shared.restoreAnswer(record.answer.practice)
        lastSwipe = nil
        pendingAnswer = nil
        choicePick = nil
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            if !record.gotIt, queue.last?.id == record.card.id {
                queue.removeLast()
            }
            queue.insert(record.card, at: 0)
            isFlipped = false
        }
    }

    /// One-time teaching beat: after the first-ever flip the card eases toward
    /// the edge and springs back, previewing the swipe and the rise behind it.
    private func maybeHintSwipe() {
        guard !hasSwipedDeck, !didHint, queue.count > 1 else { return }
        didHint = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 700_000_000)
            guard !hasSwipedDeck, !isFlinging, drag == .zero, isFlipped else { return }
            withAnimation(.spring(response: 0.38, dampingFraction: 0.6)) {
                drag = CGSize(width: 52, height: 0)
            }
            try? await Task.sleep(nanoseconds: 430_000_000)
            guard !isFlinging else { return }
            withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) {
                drag = .zero
            }
        }
    }
}

// MARK: - Card faces

/// One card, both faces, flipped as a single rigid unit: the whole card
/// rotates and the face swap happens exactly at 90°, when the card is
/// edge-on and invisible. Rotating the faces inside a static background is
/// what made the text detach from the card (the Sideline deck fix).
struct FlipCardFace: View {
    let card: Flashcard
    let isFlipped: Bool
    var accent: Color = Theme.jade
    var choicePick: Int?
    var onChoose: ((Int) -> Void)?
    var onAdvance: (() -> Void)? = nil
    /// The deck grades by swipe; the mixed session grades with buttons.
    var showsSwipeHints = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var shineTrigger = 0

    var body: some View {
        Group {
            if reduceMotion {
                // No half-turn in 3D: the faces cross-fade in place.
                ZStack {
                    if isFlipped { back.transition(.opacity) } else { front.transition(.opacity) }
                }
            } else {
                FlipRotation(angle: isFlipped ? 180 : 0) {
                    front
                } back: {
                    back
                }
            }
        }
        .shine(trigger: reduceMotion ? 0 : shineTrigger, corner: Theme.deckCorner)
        // A plain card is one element, so the deck's flip and grading
        // actions land on it. A choice card keeps its buttons reachable.
        .accessibilityElement(children: card.choice == nil || (isFlipped && onAdvance == nil) ? .combine : .contain)
        .accessibilityLabel(isFlipped ? backSpoken : frontSpoken)
        .task(id: isFlipped) {
            // A correct call earns the slot-machine gleam once the flip lands.
            guard isFlipped, verdict?.correct == true else { return }
            try? await Task.sleep(nanoseconds: 450_000_000)
            shineTrigger += 1
        }
    }

    /// 52pt tiles fit five across the card. A wider row (a seven-tile run)
    /// shrinks its tiles instead of stretching the card past the screen edge,
    /// which also stretched every card stacked behind it.
    private var frontTileWidth: CGFloat {
        let count = card.frontTiles.count
        let rows = max(1, (count + 6) / 7)
        let widest = (count + rows - 1) / rows
        switch widest {
        case ...5: return 52
        case 6: return 44
        default: return 38
        }
    }

    private var front: some View {
        MahjCardFace(accent: accent, eyebrow: String(localized: "MAHJ TRAINER")) {
            VStack(spacing: 18) {
                Spacer(minLength: 0)
                Text(card.frontTitle)
                    .font(Theme.display(25))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                if !card.frontTiles.isEmpty {
                    TileRackView(tiles: card.frontTiles, tileWidth: frontTileWidth)
                }
                if let subtitle = card.frontSubtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(Theme.inkSecondary)
                        .multilineTextAlignment(.center)
                }
                Spacer(minLength: 0)
                if let choice = card.choice, let onChoose {
                    choiceButtons(choice, onChoose: onChoose)
                } else {
                    Label("Tap to reveal", systemImage: "hand.tap.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.inkTertiary)
                }
            }
        }
    }

    private var back: some View {
        MahjCardFace(accent: accent, eyebrow: String(localized: "THE CALL")) {
            if dynamicTypeSize.isAccessibilitySize {
                accessibleBack
            } else {
                VStack(spacing: 14) {
                    if let verdict {
                        verdictBanner(verdict)
                    }
                    Spacer(minLength: 0)
                    answerText
                    Spacer(minLength: 0)
                    if showsSwipeHints {
                        if let onAdvance {
                            nextButton(onAdvance)
                        } else {
                            swipeHint
                        }
                    }
                }
            }
        }
    }

    /// The card has a fixed height, and at accessibility sizes the verdict,
    /// the title and the hint left room for a line or two of the answer, cut
    /// off with nothing to say there was more. Here everything but Next
    /// scrolls as one, with the indicator shown and flashed on the flip.
    private var accessibleBack: some View {
        VStack(spacing: 14) {
            ScrollView {
                VStack(spacing: 14) {
                    if let verdict {
                        verdictBanner(verdict)
                    }
                    answerText
                    if showsSwipeHints, onAdvance == nil {
                        swipeHint
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.visible)
            .scrollIndicatorsFlash(onAppear: true)
            .scrollBounceBehavior(.basedOnSize)
            .hidesScrollEdgeEffect()
            if showsSwipeHints, let onAdvance {
                nextButton(onAdvance)
            }
        }
    }

    private func nextButton(_ onAdvance: @escaping () -> Void) -> some View {
        Button(action: onAdvance) {
            Text("Next").primaryCTA(color: accent)
        }
    }

    private var swipeHint: some View {
        Label("Knew it? Swipe right · Again? Swipe left", systemImage: "hand.draw.fill")
            .font(.caption.weight(.semibold))
            .foregroundStyle(Theme.inkTertiary)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// The whole front, not just its title: on a card like "How many
    /// tiles?" the question lives in the subtitle and the tiles.
    private var frontSpoken: String {
        var parts = [card.frontTitle]
        if let subtitle = card.frontSubtitle, !subtitle.isEmpty { parts.append(subtitle) }
        if !card.frontTiles.isEmpty { parts.append(card.frontTiles.map(\.spokenName).joined(separator: ", ")) }
        return parts.joined(separator: ". ")
    }

    /// Leads with the verdict on a graded card, so the grade is heard first.
    private var backSpoken: String {
        let answer = "\(card.backTitle). \(card.backBody)"
        guard let verdict else { return answer }
        return verdict.correct
            ? String(localized: "Right. \(answer)")
            : String(localized: "Not this time. \(answer)")
    }

    private var answerText: some View {
        VStack(spacing: 14) {
            Text(card.backTitle)
                .font(Theme.display(22))
                .foregroundStyle(accent)
                .multilineTextAlignment(.center)
            Rectangle()
                .fill(Theme.rule)
                .frame(width: 44, height: 2)
            Text(card.backBody)
                .font(.body)
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var verdict: (text: String, correct: Bool)? {
        guard let choice = card.choice, let pick = choicePick else { return nil }
        let correct = pick == choice.answerIndex
        return (String(localized: "You said \"\(choice.options[pick])\""), correct)
    }

    private func verdictBanner(_ verdict: (text: String, correct: Bool)) -> some View {
        HStack(spacing: 8) {
            Image(systemName: verdict.correct ? "checkmark.circle.fill" : "xmark.circle.fill")
            Text(verdict.correct ? String(localized: "\(verdict.text). Right!") : String(localized: "\(verdict.text). Not this time."))
                .font(.footnote.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(verdict.correct ? Theme.jade : Theme.coral)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background((verdict.correct ? Theme.jade : Theme.coral).opacity(0.13), in: Capsule())
    }

    /// Displays the two options in a deterministic, per-card shuffled order
    /// (seeded by the card id) so the answer isn't always the left/first
    /// button, but reports the ORIGINAL option index back to `onChoose` so
    /// grading stays against the authored `answerIndex` unchanged.
    private func choiceButtons(_ choice: CardChoice, onChoose: @escaping (Int) -> Void) -> some View {
        let order = ChoiceShuffle.permutation(count: choice.options.count, seed: card.id)
        return VStack(spacing: 8) {
            Text("Make the call")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.inkTertiary)
            HStack(spacing: 10) {
                ForEach(order, id: \.self) { index in
                    Button {
                        onChoose(index)
                    } label: {
                        Text(choice.options[index])
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(accent)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.8)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 44)
                            .background(accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 13, style: .continuous)
                                    .strokeBorder(accent.opacity(0.45), lineWidth: 1.5)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

/// The mahjong-card chrome both faces share: ivory surface, double frame like
/// the printed card, corner pips, and a faint tile-glyph watermark so the
/// open space feels designed instead of empty.
private struct MahjCardFace<Content: View>: View {
    let accent: Color
    let eyebrow: String
    @ViewBuilder let content: () -> Content
    @Environment(\.isDeckScenery) private var isDeckScenery

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                frameDot
                Text(eyebrow)
                    .font(.caption2.weight(.heavy))
                    .kerning(2.2)
                    .foregroundStyle(accent.opacity(0.65))
                frameDot
            }
            content()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            RoundedRectangle(cornerRadius: Theme.deckCorner, style: .continuous)
                .fill(Theme.card)
        }
        .overlay {
            // Watermark sits above the surface but below the frame.
            Text("麻")
                .font(.system(size: 190, weight: .bold))
                .foregroundStyle(accent.opacity(0.05))
                .rotationEffect(.degrees(-10))
                .offset(x: 60, y: 70)
                // Zero minimums hold the frame to the card. Without them a
                // card shorter than the glyph (a Duo pane's deck) grew the
                // frame, and the clip let the glyph spill onto the deck.
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .bottomTrailing)
                .clipShape(RoundedRectangle(cornerRadius: Theme.deckCorner, style: .continuous))
                // Only the top card carries it. The cards behind drew theirs
                // in the strips that peek below, which lined up into one glyph
                // running off the top card's edge.
                .opacity(isDeckScenery ? 0 : 1)
                .allowsHitTesting(false)
        }
        .overlay {
            RoundedRectangle(cornerRadius: Theme.deckCorner, style: .continuous)
                .strokeBorder(Theme.rule, lineWidth: 1)
        }
        .overlay {
            RoundedRectangle(cornerRadius: Theme.deckCorner - 9, style: .continuous)
                .strokeBorder(accent.opacity(0.28), lineWidth: 1.5)
                .padding(9)
                .allowsHitTesting(false)
        }
        .shadow(color: .black.opacity(0.10), radius: 14, y: 6)
    }

    private var frameDot: some View {
        Circle()
            .fill(accent.opacity(0.4))
            .frame(width: 4, height: 4)
    }
}

/// Animatable 3D flip that swaps faces at the 90° midpoint. Conforming the
/// view itself to Animatable means SwiftUI interpolates `angle` every frame,
/// so the swap always happens while the card is edge-on.
// @preconcurrency: Animatable's requirement is nonisolated but SwiftUI only
// ever drives animatableData on the main thread, where this view lives.
private struct FlipRotation<Front: View, Back: View>: View, @preconcurrency Animatable {
    var angle: Double
    @ViewBuilder let front: () -> Front
    @ViewBuilder let back: () -> Back

    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    var body: some View {
        ZStack {
            if angle < 90 {
                front()
            } else {
                // Pre-mirrored so it reads correctly once the container hits 180°.
                back()
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            }
        }
        .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), perspective: 0.35)
    }
}

private extension EnvironmentValues {
    /// True for the cards stacked behind the deck's top card.
    @Entry var isDeckScenery = false
}

private extension View {
    /// iOS 26 hangs the navigation bar's scroll-edge blur on the first
    /// scroll view it finds. On the flashcard back that is the answer's
    /// scroll view inside the card, so the blur sat over the card's title.
    @ViewBuilder
    func hidesScrollEdgeEffect() -> some View {
        if #available(iOS 26, *) {
            scrollEdgeEffectHidden(true, for: .all)
        } else {
            self
        }
    }
}
