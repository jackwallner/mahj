import SwiftUI

/// Where the correct answer row sits, published up to whichever drill is
/// hosting it, so a celebration can fire FROM the thing that was right instead
/// of from the middle of the screen. Reported in the `.drillStage` coordinate
/// space, which the host installs on its root.
struct AnswerRowFrameKey: PreferenceKey {
    static let defaultValue: CGRect? = nil

    static func reduce(value: inout CGRect?, nextValue: () -> CGRect?) {
        value = nextValue() ?? value
    }
}

extension CoordinateSpace {
    static let drillStageName = "drillStage"
}

extension View {
    /// Installs the coordinate space the winning answer row reports into, and
    /// binds that row's frame so the host can fire its celebration from it.
    func drillStage(answerRect: Binding<CGRect?>) -> some View {
        coordinateSpace(name: CoordinateSpace.drillStageName)
            .onPreferenceChange(AnswerRowFrameKey.self) { [answerRect] rect in
                answerRect.wrappedValue = rect
            }
    }
}

extension EnvironmentValues {
    /// Tighter question metrics for a viewport too short for the regular ones
    /// (an unfolded iPhone Duo pane, an iPhone SE). Set by `QuestionPager`.
    @Entry var compactQuestion = false
}

/// Scroll target for the coaching note revealed on grading. Lives outside
/// `QuestionPager` because a generic type cannot hold a static stored property.
private let questionExplanationID = "question-explanation"

/// Shared question scaffolding: prompt + tiles + choices + explanation, the
/// shape every choice-based drill uses (Quiz, Hand Match, Quick Session).
struct QuestionPager<Choices: View>: View {
    let prompt: String
    let tiles: [Tile]
    let explanation: String
    let answered: Bool
    /// The room/source eyebrow. It belongs INSIDE the pager so it centres with
    /// the question: pinned above it on an iPad, the eyebrow sat alone at the
    /// top with a hand's width of empty cream between it and the prompt.
    var eyebrow: String? = nil
    /// Set only when the player got it WRONG and there is something specific
    /// to say about the answer they actually chose. The generic explanation
    /// tells them what is right; this tells them why their read was wrong,
    /// which is the half that changes the next answer.
    var missNote: MissNote? = nil
    /// True when this miss just went back into the review schedule. Saying so
    /// turns a wrong answer from a score into a plan.
    var requeued: Bool = false
    @ViewBuilder let choices: () -> Choices

    /// Nil until the regular layout has been measured against the viewport.
    /// Decided once per question, before grading, so the explanation growing
    /// the content never flips the metrics under the player mid-answer.
    @State private var compact: Bool?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var viewportHeight: CGFloat = 0
    @State private var questionHeight: CGFloat = 0
    /// The graded note has been scrolled to for this answer.
    @State private var noteScrolled = false

    var body: some View {
        // The reader wraps the scroll view: inside its content, `scrollTo`
        // never moved it, and at AX3 the note stayed behind Next (1.4.2).
        ScrollViewReader { proxy in
            pager(proxy)
        }
    }

    private func pager(_ proxy: ScrollViewProxy) -> some View {
        // Centering, not top-aligned: on a 13-inch iPad a three-choice question
        // used to sit in the top quarter of the screen. See CenteringScrollView.
        // iOS 18: a graded question that grows keeps its bottom, the note,
        // in view. Only once graded: before that, the compact switch must
        // not scroll an unanswered question off its prompt.
        CenteringScrollView(keepsBottom: answered) {
            VStack(spacing: isCompact ? 12 : 20) {
                VStack(spacing: isCompact ? 12 : 20) {
                    if let eyebrow {
                        Text(eyebrow)
                            .font(.caption2.weight(.heavy))
                            .kerning(1.4)
                            .foregroundStyle(Theme.inkTertiary)
                            .padding(.bottom, -8)
                    }
                    Text(prompt)
                        .accessibilityIdentifier("question-prompt")
                        .font(Theme.display(isCompact ? 19 : 22))
                        .foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.center)
                        .padding(.top, isCompact ? 0 : 8)
                    if !tiles.isEmpty {
                        TileRackView(tiles: tiles, tileWidth: isCompact ? 36 : 44)
                    }
                    choices()
                }
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
                    questionHeight = height
                    fit()
                }
                if answered {
                    VStack(spacing: 10) {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(Theme.gold)
                            Text(explanation)
                                .accessibilityIdentifier("question-explanation")
                                .font(.subheadline)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                        if let missNote {
                            MissNoteCard(note: missNote)
                        }
                        if requeued {
                            RequeuedChip()
                        }
                    }
                    .id(questionExplanationID)
                    // Held back until the rows have moved: inserted at its
                    // final spot while the stack above slid up, the note sat
                    // under the last choice for a quarter second.
                    .transition(.asymmetric(
                        insertion: reduceMotion ? .identity : .opacity.animation(.easeOut(duration: 0.22).delay(0.2)),
                        removal: .identity
                    ))
                }
            }
            // Headroom so the winning row's pop and glow have somewhere to go.
            // A ScrollView clips its content, so a row that scales up to the
            // full content width would get its sides sheared off (that was the
            // "glitchy edges" on the correct answer). The padding is what buys
            // that room. Do NOT reach for `scrollClipDisabled()` instead: an
            // unclipped scroll view draws its overflow straight through the
            // navigation bar above and the drill's Next button below.
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            // One hidden frame while the regular layout is measured, so a
            // short screen never shows it and then snaps to the compact one.
            .opacity(compact == nil ? 0 : 1)
            .environment(\.compactQuestion, isCompact)
            // Bring the coaching note into view rather than leaving it
            // parked below the fold behind the Next button. Scrolled once
            // the content has grown to hold it (from `onChange(of:
            // answered)` the note had no frame yet), on the next main-queue
            // turn (a scroll asked for inside the layout pass is dropped).
            // At AX3 the note stayed behind Next (release gate, 1.4.2).
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { _ in
                guard answered, !noteScrolled else { return }
                noteScrolled = true
                Task { @MainActor in scrollToNote(proxy) }
            }
        }
        .onChange(of: answered) { _, isAnswered in
            if !isAnswered { noteScrolled = false }
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
            // Unfolding or rotating changes the room: measure again.
            if abs(height - viewportHeight) > 1, !answered { compact = nil }
            viewportHeight = height
            fit()
        }
        // The prompt, tiles and choices move as ONE when the note makes the
        // content taller and the centring shifts. Each row used to animate on
        // its own while everything around it jumped, so the rows slid across
        // the coaching note (2026-10-19 frame capture).
        .animation(reduceMotion ? nil : Self.gradeSpring, value: answered)
    }

    private func scrollToNote(_ proxy: ScrollViewProxy) {
        // The anchor was audited (REG94-003) on the theory that
        // `.bottom` pins the block to the foot of the viewport and
        // throws the prompt off the top. It does not, and dropping
        // the anchor for a minimum scroll changes NOTHING: this block
        // is the last thing in the VStack, and `CenteringScrollView`
        // gives the content a minHeight of the viewport, so either
        // the question fits and there is no scroll range at all, or
        // it overflows and both spellings land at the same place.
        // Leave it alone. What a tall coaching block costs the prompt
        // is a content-height problem, not a scroll-anchor one.
        // Reduce Motion: the note fades in and the scroll jumps.
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.35)) {
            proxy.scrollTo(questionExplanationID, anchor: .bottom)
        }
    }

    static var gradeSpring: Animation { .spring(response: 0.3, dampingFraction: 0.8) }

    private var isCompact: Bool { compact ?? false }

    /// Compact only when the regular question (prompt, tiles, choices and the
    /// pager's 10pt padding) would not fit, so the player never has to scroll
    /// to reach the last choice.
    private func fit() {
        guard compact == nil, viewportHeight > 0, questionHeight > 0 else { return }
        compact = questionHeight + 20 > viewportHeight
    }
}

/// The answer buttons every question type shares. On reveal the correct
/// answer LANDS: it pops, glows, and a shine sweeps across it, and the graded
/// state holds until the drill's Next button advances and never auto-skips.
///
/// Two rules learned the hard way: (1) the correct row is never dimmed, ever.
/// It's the answer the player is supposed to be reading. (2) Nothing here uses
/// `.disabled()` to stop taps after grading, because SwiftUI dims disabled
/// button labels, and that dimming hit the winning row.
struct ChoiceList: View {
    let labels: [String]
    let selection: Int?
    let answerIndex: Int
    let onPick: (Int) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.compactQuestion) private var compact
    @State private var shineTrigger = 0
    @State private var landed = false
    @State private var shakes: CGFloat = 0

    private var answered: Bool { selection != nil }

    var body: some View {
        VStack(spacing: compact ? 8 : 10) {
            ForEach(labels.indices, id: \.self) { index in
                row(index)
                    .accessibilityIdentifier("choice-\(index)")
            }
        }
        .onChange(of: answered) { _, isAnswered in
            guard isAnswered else {
                // New question: reset the celebration state.
                landed = false
                shakes = 0
                return
            }
            announceGrade()
            // Reduce Motion keeps the colours, icons and border that carry
            // the grade, and drops the pop, the shine and the shake.
            guard !reduceMotion else {
                landed = true
                return
            }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.5).delay(0.05)) {
                landed = true
            }
            shineTrigger += 1
            if selection != answerIndex {
                withAnimation(.linear(duration: 0.4)) { shakes = 2 }
            }
        }
    }

    private func row(_ index: Int) -> some View {
        let isAnswer = index == answerIndex
        let isMiss = answered && index == selection && !isAnswer
        // Wrong rows the player didn't pick recede a little so the eye goes to
        // the answer, but they stay readable: the miss and the answer are the
        // two rows that matter and neither is faded.
        let recedes = answered && !isAnswer && !isMiss
        return Button {
            onPick(index)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Text(labels[index])
                    .font(.body.weight(answered && isAnswer ? .semibold : .medium))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.leading)
                    // Without this a long answer is squeezed onto one line and
                    // ends in an ellipsis. These labels are teaching content,
                    // and the moment the player most needs to read one in full
                    // is right after grading. It goes on the Text, before the
                    // frame, the way every other wrapping label here does.
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                // A fixed slot, occupied or not: the icon appears on grading,
                // and if it took its width from the label then the label
                // rewrapped underneath the answer the player is reading.
                resultIcon(isAnswer: isAnswer, isMiss: isMiss)
                    .frame(width: 22, alignment: .center)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, compact ? 11 : 16)
            .frame(maxWidth: .infinity)
            .background(background(index), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(border(index), lineWidth: answered && isAnswer ? 2.5 : 1)
            )
            .background {
                // Publish the winning row's position for the host's confetti.
                if isAnswer {
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: AnswerRowFrameKey.self,
                            value: geo.frame(in: .named(CoordinateSpace.drillStageName))
                        )
                    }
                }
            }
            .shine(trigger: answered && isAnswer ? shineTrigger : 0)
            .winGlow(Theme.bamGreen, active: answered && isAnswer && landed)
            .scaleEffect(answered && isAnswer && landed ? 1.035 : 1)
            .modifier(ShakeEffect(travels: isMiss ? shakes : 0))
            .opacity(recedes ? 0.72 : 1)
            .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.8), value: answered)
        }
        .buttonStyle(.plain)
        .allowsHitTesting(!answered)
        // The grade is otherwise colour, a border and an icon: say it.
        .accessibilityValue(gradeDescription(isAnswer: isAnswer, isPick: index == selection))
        .accessibilityAddTraits(index == selection ? .isSelected : [])
    }

    private func gradeDescription(isAnswer: Bool, isPick: Bool) -> String {
        guard answered else { return "" }
        switch (isAnswer, isPick) {
        case (true, true): return "Your answer, correct"
        case (true, false): return "Correct answer"
        case (false, true): return "Your answer, wrong"
        case (false, false): return ""
        }
    }

    private func announceGrade() {
        guard let selection, labels.indices.contains(answerIndex) else { return }
        let message = selection == answerIndex
            ? "Correct."
            : "Not quite. The answer is \(labels[answerIndex])."
        AccessibilityNotification.Announcement(message).post()
    }

    /// Always returns something 22pt wide so the label's width never changes
    /// between the unanswered and the graded state.
    @ViewBuilder
    private func resultIcon(isAnswer: Bool, isMiss: Bool) -> some View {
        if answered && isAnswer {
            Image(systemName: "checkmark.circle.fill")
                .font(.body.weight(.bold))
                .foregroundStyle(Theme.bamGreen)
                .scaleEffect(landed ? 1.2 : 0.4)
        } else if answered && isMiss {
            Image(systemName: "xmark.circle.fill")
                .font(.body.weight(.bold))
                .foregroundStyle(Theme.crakRed)
        } else {
            Color.clear.frame(width: 22, height: 22)
        }
    }

    private func background(_ index: Int) -> Color {
        guard answered else { return Theme.card }
        if index == answerIndex { return Theme.bamGreen.opacity(0.18) }
        if index == selection { return Theme.crakRed.opacity(0.15) }
        return Theme.card
    }

    private func border(_ index: Int) -> Color {
        guard answered else { return Theme.rule }
        if index == answerIndex { return Theme.bamGreen.opacity(0.6) }
        if index == selection { return Theme.crakRed.opacity(0.5) }
        return Theme.rule
    }
}


/// What the player picked, and why it was not the answer.
struct MissNote: Equatable, Sendable {
    let pickedLabel: String
    let reason: String
}

/// The second half of a wrong answer. The gold card above says what IS true;
/// this says what the player's own read would have required, which is the
/// part that stops them making the same read next time.
///
/// Deliberately NOT a disclosure. It was one, and it was wrong twice over: a
/// player who has just got something wrong should not have to ask a second
/// time to find out why, and expanding it after the pager had already scrolled
/// pushed the reason underneath the Next button, where the last line was cut
/// in half.
struct MissNoteCard: View {
    let note: MissNote

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "questionmark.circle.fill")
                    .foregroundStyle(Theme.crakRed)
                Text("Why not \(note.pickedLabel)?")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            Text(note.reason)
                .font(.subheadline)
                .foregroundStyle(Theme.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.crakRed.opacity(0.09), in: RoundedRectangle(cornerRadius: 14))
    }
}

/// "We will ask you this again." A miss that visibly schedules itself reads as
/// the app catching you rather than scoring you.
struct RequeuedChip: View {
    @EnvironmentObject private var subscriptions: SubscriptionService

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "arrow.trianglehead.counterclockwise")
                .font(.caption)
            // Fix My Mistakes is a Mahj+ tile; a free player's misses still
            // come back first in Get Started, so promise that instead.
            Text(subscriptions.isPro ? "Saved to Fix My Mistakes" : "This one will come back")
                .font(.caption.weight(.semibold))
            Spacer(minLength: 0)
        }
        .foregroundStyle(Theme.plum)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.plum.opacity(0.11), in: Capsule())
    }
}

extension String {
    /// Sentence-cases a fragment that was authored to sit mid-sentence.
    var capitalizedFirst: String {
        guard let first else { return self }
        return first.uppercased() + dropFirst()
    }
}

extension AnyTransition {
    /// The slide between questions. With Reduce Motion on, a plain cross-fade.
    ///
    /// The old question leaves at once and the new one eases in from a short
    /// distance. Two full-width slides crossing with a fade drew both tile
    /// racks on top of each other mid-swap, and the old question, still
    /// scrolled to its coaching note, sat higher than the new one, so the
    /// header jumped. Even a 0.1s fade-out left six double-exposed frames
    /// (2026-10-19 frame capture).
    static func questionSlide(reduceMotion: Bool) -> AnyTransition {
        guard !reduceMotion else { return .opacity }
        return .asymmetric(
            insertion: .offset(x: 40).combined(with: .opacity),
            removal: .identity
        )
    }
}

/// Next on a graded item. Two quick taps both land before the button hides,
/// so each reads the live state: the first clears the answer (or finishes the
/// drill) and the second finds nothing to advance. Without it the second tap
/// skipped a question, and from the second to last it finished the drill
/// with the last one unanswered.
enum DrillNext {
    static func allowed(answered: Bool, finished: Bool) -> Bool {
        answered && !finished
    }
}
