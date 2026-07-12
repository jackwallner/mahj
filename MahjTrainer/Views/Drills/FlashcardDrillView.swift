import SwiftUI

/// Flashcards as a swipeable deck. The grammar: tap flips the card to reveal
/// the answer; only a flipped card can be swiped — right means "got it" (card
/// leaves the deck), left means "again" (card returns at the back). Before the
/// flip a horizontal drag rubber-bands, so the reveal always comes first.
struct FlashcardDrillView: View {
    let drill: Drill
    let cards: [Flashcard]

    @State private var queue: [Flashcard] = []
    @State private var isFlipped = false
    @State private var drag: CGSize = .zero
    @State private var isFlinging = false
    @State private var crossedThreshold = false
    @State private var lastSwipe: SwipeRecord?
    @State private var finished = false

    /// One-time teaching nudge after the first-ever flip.
    @AppStorage("mahj.hasSwipedDeck") private var hasSwipedDeck = false
    @State private var didHint = false

    private struct SwipeRecord {
        let card: Flashcard
        let gotIt: Bool
    }

    var body: some View {
        if finished {
            DrillCompleteView(drill: drill, score: nil, total: cards.count)
        } else {
            drillBody
                .onAppear {
                    if queue.isEmpty { queue = cards }
                }
        }
    }

    private var mastered: Int { cards.count - queue.count }

    private var drillBody: some View {
        VStack(spacing: 14) {
            header
            GeometryReader { geo in
                deck(size: geo.size)
            }
            .padding(.horizontal, 4)
        }
        .padding()
        .background(Theme.background)
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
                    .accessibilityLabel("Undo last swipe")
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
                        .fill(Theme.jade)
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
                FlipCardFace(card: card, isFlipped: slot == 0 && isFlipped)
                    .scaleEffect(scale(forSlot: slot))
                    .offset(y: yOffset(forSlot: slot))
                    .offset(slot == 0 ? effectiveDrag : .zero)
                    .rotationEffect(slot == 0 ? topRotation : .zero, anchor: .bottom)
                    .overlay { if slot == 0 { verdictStamps } }
                    .zIndex(Double(3 - slot))
                    .allowsHitTesting(slot == 0)
                    .gesture(dragGesture(size: size))
                    .accessibilityAddTraits(.isButton)
                    .accessibilityHint(isFlipped ? "Swipe right if you knew it, left to review again" : "Tap to reveal the answer")
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

    /// GOT IT / AGAIN stamps fade in with the drag so the swipe directions
    /// carry their meaning on the card itself.
    private var verdictStamps: some View {
        ZStack {
            stamp("GOT IT", color: Theme.jade, angle: -12)
                .opacity(isFlipped ? stampOpacity(forDirection: 1) : 0)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            stamp("AGAIN", color: Theme.coral, angle: 12)
                .opacity(isFlipped ? stampOpacity(forDirection: -1) : 0)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }
        .padding(22)
        .allowsHitTesting(false)
    }

    private func stamp(_ text: String, color: Color, angle: Double) -> some View {
        Text(text)
            .font(.system(size: 26, weight: .heavy, design: .rounded))
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

    private var progress: CGFloat {
        guard isFlipped else { return 0 }
        return min(1, abs(drag.width) / 110)
    }

    private func restingScale(_ slot: Int) -> CGFloat { 1 - CGFloat(slot) * 0.04 }
    private func restingY(_ slot: Int) -> CGFloat { CGFloat(slot) * 24 }

    private func scale(forSlot slot: Int) -> CGFloat {
        guard slot > 0 else { return 1 }
        return restingScale(slot) + (restingScale(slot - 1) - restingScale(slot)) * progress
    }

    private func yOffset(forSlot slot: Int) -> CGFloat {
        guard slot > 0 else { return 0 }
        return restingY(slot) + (restingY(slot - 1) - restingY(slot)) * progress
    }

    private var topRotation: Angle {
        .degrees(Double(max(-12, min(12, effectiveDrag.width / 14))))
    }

    // MARK: - Gestures

    private func flip() {
        guard !isFlinging else { return }
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

    /// Throw the card off, then commit the grade with animation suppressed —
    /// the risen card behind is already in place, so nothing jumps.
    private func fling(direction: CGFloat, size: CGSize) {
        isFlinging = true
        hasSwipedDeck = true
        Haptics.impact(.rigid, intensity: 0.7)
        let exit = CGSize(width: direction * size.width * 1.5, height: drag.height * 1.1)
        withAnimation(.easeIn(duration: 0.26)) {
            drag = exit
        } completion: {
            var t = Transaction()
            t.disablesAnimations = true
            withTransaction(t) {
                commit(gotIt: direction > 0)
                drag = .zero
                isFlinging = false
                isFlipped = false
            }
        }
    }

    private func commit(gotIt: Bool) {
        guard let card = queue.first else { return }
        lastSwipe = SwipeRecord(card: card, gotIt: gotIt)
        queue.removeFirst()
        if !gotIt {
            queue.append(card)
        }
        if queue.isEmpty {
            Haptics.success()
            withAnimation(.easeInOut(duration: 0.3)) { finished = true }
        }
    }

    private func undo() {
        guard let record = lastSwipe, !isFlinging else { return }
        Haptics.impact(.light)
        lastSwipe = nil
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

/// One card, both faces. The hidden face never draws text backwards and never
/// steals touches.
private struct FlipCardFace: View {
    let card: Flashcard
    let isFlipped: Bool

    var body: some View {
        ZStack {
            front
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                .opacity(isFlipped ? 0 : 1)
                .accessibilityHidden(isFlipped)
            back
                .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
                .opacity(isFlipped ? 1 : 0)
                .accessibilityHidden(!isFlipped)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: Theme.deckCorner, style: .continuous)
                .fill(Theme.card)
                .shadow(color: .black.opacity(0.10), radius: 14, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.deckCorner, style: .continuous)
                .strokeBorder(Theme.rule, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isFlipped ? "\(card.backTitle). \(card.backBody)" : card.frontTitle)
    }

    private var front: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 0)
            Text(card.frontTitle)
                .font(Theme.display(26))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            if !card.frontTiles.isEmpty {
                TileRackView(tiles: card.frontTiles, tileWidth: 52)
            }
            if let subtitle = card.frontSubtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSecondary)
                    .multilineTextAlignment(.center)
            }
            Spacer(minLength: 0)
            Label("Tap to reveal", systemImage: "hand.tap.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.inkTertiary)
        }
        .padding(26)
    }

    private var back: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 0)
            Text(card.backTitle)
                .font(Theme.display(22))
                .foregroundStyle(Theme.jade)
                .multilineTextAlignment(.center)
            Rectangle()
                .fill(Theme.rule)
                .frame(width: 44, height: 2)
            Text(card.backBody)
                .font(.body)
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Label("Knew it? Swipe right · Again? Swipe left", systemImage: "hand.draw.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.inkTertiary)
        }
        .padding(26)
    }
}
