import SwiftUI

/// The How to Play quick start: a short primer on American Mah Jongg for
/// brand-new players. Runs inside onboarding (pass `onDone`, and `onSkip` for
/// the escape hatch) and re-opens from Home and Settings (dismisses itself).
///
/// Navigation is both swipe and button: drag the card left/right to page, and
/// Back sits NEXT to Continue where the thumb already is. (A back chevron in
/// the top-left corner is a mile from the thumb on the same screen where the
/// forward action is a full-width button at the bottom.)
struct HowToPlayView: View {
    var onDone: (() -> Void)?
    var onSkip: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.layoutDirection) private var layoutDirection
    @AppStorage("mahj.skillLevel") private var skillLevel = ""
    @AppStorage("mahj.recommendedRoomHint") private var recommendedRoomHint = ""
    /// Read to the end once: Home stops showing the primer card, and the
    /// primer becomes a Settings row like any other reference.
    @AppStorage("mahj.hasReadPrimer") private var hasReadPrimer = false
    @State private var index = 0
    @State private var goingForward = true
    @State private var shineTrigger = 0
    @State private var confettiTrigger = 0
    @State private var drag: CGFloat = 0

    private let pages = HowToPlayContent.pages
    private var page: HowToPlayPage { pages[index] }
    private var isLast: Bool { index == pages.count - 1 }
    private var isFirst: Bool { index == 0 }
    private var recommendedRoom: Room { HowToPlayContent.recommendedRoom(forSkillLevel: skillLevel) }

    var body: some View {
        VStack(spacing: 18) {
            progressDots
            if dynamicTypeSize.isAccessibilitySize {
                // At the largest sizes a page outgrows the screen and pushed
                // Continue and Skip below it with no way to reach them. The
                // page scrolls there, from the top on every page; the footer
                // stays put.
                ScrollView { movingCard(swipes: false) }
                    .id(page.id)
            } else {
                // Centred as designed where it fits. On an iPhone SE the
                // longest pages are taller than the screen and pushed the
                // dots under the status bar and Skip off the bottom, so
                // those scroll instead.
                ViewThatFits(in: .vertical) {
                    // Every page's top sits where the tallest page's would,
                    // centred, so the title is not hunted for on each page.
                    StablePageTop {
                        ForEach(pages) { pageCard($0).hidden().accessibilityHidden(true) }
                        movingCard(swipes: true)
                    }
                    ScrollView { movingCard(swipes: false) }
                        .id(page.id)
                }
            }
            footer
        }
        .padding()
        .frame(maxWidth: Theme.readableContentWidth)
        .frame(maxWidth: .infinity)
        .background(Theme.background)
        .overlay { ConfettiBurst(trigger: confettiTrigger, origin: .init(x: 0.5, y: 0.35)) }
        .analyticsScreen("How to Play")
        .navigationTitle("How to Play")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { fireShine() }
    }

    /// The page card with its swipe, tilt and page transition. Inside a
    /// scroll view the swipe is off: it took every drag, vertical ones too,
    /// so the end of a long page on an iPhone SE could not be scrolled to.
    /// Back and Continue still page there.
    private func movingCard(swipes: Bool) -> some View {
        pageCard(page)
            .shine(trigger: shineTrigger, corner: 22)
            .id(page.id)
            .offset(x: drag)
            .rotationEffect(.degrees(Double(drag / 40)), anchor: .bottom)
            .transition(goingForward
                ? .asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                )
                : .asymmetric(
                    insertion: .move(edge: .leading).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                )
            )
            .gesture(pageSwipe, including: swipes ? .all : .subviews)
    }

    /// Swipe toward the leading edge for the next page (left, or right in
    /// Arabic), the other way for the previous one. The card tracks the
    /// finger and rubber-bands at both ends of the primer.
    private var pageSwipe: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                let travel = leadingward(value.translation.width)
                let atEdge = (travel > 0 && isFirst) || (travel < 0 && isLast)
                drag = atEdge ? travel * 0.25 : travel
            }
            .onEnded { value in
                let travel = leadingward(value.translation.width)
                let flung = abs(travel) > 60 || abs(value.predictedEndTranslation.width) > 160
                withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.8)) { drag = 0 }
                guard flung else { return }
                if travel < 0, !isLast {
                    advance()
                } else if travel > 0, !isFirst {
                    goBack()
                }
            }
    }

    /// The finger's travel in layout terms: negative toward the leading
    /// edge. Right to left SwiftUI mirrors the card's offset and its page
    /// transitions, but not the finger, so Arabic flips it back here and the
    /// card follows the hand, with the next page arriving from the left.
    private func leadingward(_ width: CGFloat) -> CGFloat {
        layoutDirection == .rightToLeft ? -width : width
    }

    private var progressDots: some View {
        HStack(spacing: 6) {
            ForEach(pages.indices, id: \.self) { dot in
                Capsule()
                    .fill(dot == index ? Theme.jade : Theme.jade.opacity(0.22))
                    .frame(width: dot == index ? 20 : 7, height: 7)
                    .animation(reduceMotion ? nil : .snappy(duration: 0.22), value: index)
            }
        }
        .padding(.top, 6)
    }

    /// Back rides beside Continue, so paging in either direction is one thumb,
    /// one place. Skip only exists during onboarding, where it's a real exit.
    private var footer: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Button {
                    goBack()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundStyle(isFirst ? Theme.inkTertiary : Theme.jade)
                        .frame(width: 56, height: 56)
                        .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(Theme.rule, lineWidth: 1)
                        )
                }
                .disabled(isFirst)
                .opacity(isFirst ? 0.45 : 1)
                .accessibilityLabel("Previous page")
                Button {
                    advance()
                } label: {
                    Text(isLast ? String(localized: "Take your seat") : String(localized: "Continue")).primaryCTA()
                }
            }
            if let onSkip {
                Button {
                    recommendedRoomHint = recommendedRoom.id
                    onSkip()
                } label: {
                    Text("Skip for now")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.inkSecondary)
                }
            }
        }
    }

    private func pageCard(_ page: HowToPlayPage) -> some View {
        VStack(spacing: 16) {
            Image(systemName: page.icon)
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(Theme.jade)
                .frame(width: 76, height: 76)
                .background(Theme.jade.opacity(0.12), in: Circle())
            Text(page.title)
                .font(Theme.display(27))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            if !page.tiles.isEmpty {
                // Seven tiles at 46pt are wider than the card on every
                // iPhone and pushed the card, Back and Continue off the
                // screen. Take the largest size that fits.
                ViewThatFits(in: .horizontal) {
                    ForEach([46, 40, 36, 32], id: \.self) { width in
                        TileRackView(tiles: page.tiles, tileWidth: CGFloat(width))
                    }
                }
            }
            Text(page.body)
                .font(.body)
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if let tip = page.tip {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(Theme.gold)
                    Text(tip)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
            }
            if page.id == pages.last?.id {
                recommendationCard
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .themedCard(corner: 22)
    }

    /// The primer's real next action: a tappable card recommending a room
    /// based on the onboarding skill level. Tapping it drives the same
    /// `advance()` as the primary button below (dismiss standalone / finish
    /// onboarding), and both routes set the one-shot hint `HomeView` consumes
    /// to highlight that room.
    private var recommendationCard: some View {
        Button {
            advance()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: recommendedRoom.icon)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(recommendedRoom.accent)
                    .frame(width: 40, height: 40)
                    .background(recommendedRoom.accent.opacity(0.14), in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text("Recommended: \(recommendedRoom.name)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.ink)
                    Text(recommendedRoom.tagline)
                        .font(.caption)
                        .foregroundStyle(Theme.inkSecondary)
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.inkTertiary)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(recommendedRoom.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(recommendedRoom.accent.opacity(0.35), lineWidth: 1.2)
            )
        }
        .buttonStyle(.plain)
    }

    private func goBack() {
        guard !isFirst else { return }
        Haptics.impact(.soft, intensity: 0.5)
        goingForward = false
        withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.85)) {
            index -= 1
        }
        fireShine()
    }

    private func advance() {
        if isLast {
            Haptics.success()
            hasReadPrimer = true
            recommendedRoomHint = recommendedRoom.id
            if let onDone {
                onDone()
            } else {
                dismiss()
            }
            return
        }
        Haptics.impact(.soft, intensity: 0.6)
        goingForward = true
        withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.85)) {
            index += 1
        }
        if index == pages.count - 1 {
            confettiTrigger += 1
        }
        fireShine()
    }

    private func fireShine() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 350_000_000)
            shineTrigger += 1
        }
    }
}

/// Lays out the last subview (the page on screen) with its top where the
/// tallest subview's top would sit if centred. The others are the hidden
/// pages, there only to be measured. Centring each page on its own moved the
/// title 20 to 30pt up or down on every Continue. A page taller than the
/// space still fits: it moves up only as far as it needs.
struct StablePageTop: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let visible = subviews.last else { return .zero }
        let size = visible.sizeThatFits(ProposedViewSize(width: proposal.width, height: nil))
        let width = proposal.width ?? size.width
        guard let height = proposal.height, height.isFinite else { return CGSize(width: width, height: size.height) }
        return CGSize(width: width, height: max(height, size.height))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard let visible = subviews.last else { return }
        let free = ProposedViewSize(width: bounds.width, height: nil)
        let tallest = subviews.map { $0.sizeThatFits(free).height }.max() ?? 0
        let visibleHeight = visible.sizeThatFits(free).height
        let top = max(0, min((bounds.height - tallest) / 2, bounds.height - visibleHeight))
        for subview in subviews {
            subview.place(
                at: CGPoint(x: bounds.minX, y: bounds.minY + top),
                proposal: ProposedViewSize(width: bounds.width, height: subview.sizeThatFits(free).height)
            )
        }
    }
}
