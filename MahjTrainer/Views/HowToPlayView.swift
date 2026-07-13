import SwiftUI

/// The How to Play quick start: a short, held-until-tap primer on American
/// Mah Jongg for brand-new players. Runs inside onboarding (pass `onDone`)
/// and re-opens from Home and Settings (dismisses itself).
struct HowToPlayView: View {
    var onDone: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @AppStorage("mahj.skillLevel") private var skillLevel = ""
    @AppStorage("mahj.recommendedRoomHint") private var recommendedRoomHint = ""
    @State private var index = 0
    @State private var goingForward = true
    @State private var shineTrigger = 0
    @State private var confettiTrigger = 0

    private let pages = HowToPlayContent.pages
    private var page: HowToPlayPage { pages[index] }
    private var isLast: Bool { index == pages.count - 1 }
    private var isFirst: Bool { index == 0 }
    private var recommendedRoom: Room { HowToPlayContent.recommendedRoom(forSkillLevel: skillLevel) }

    var body: some View {
        VStack(spacing: 18) {
            header
            Spacer(minLength: 0)
            pageCard
                .id(page.id)
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
            Spacer(minLength: 0)
            Button {
                advance()
            } label: {
                Text(isLast ? "Take your seat" : "Continue").primaryCTA()
            }
        }
        .padding()
        .background(Theme.background)
        .overlay { ConfettiBurst(trigger: confettiTrigger, origin: .init(x: 0.5, y: 0.35)) }
        .navigationTitle("How to Play")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { fireShine() }
    }

    private var header: some View {
        HStack {
            Button {
                goBack()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.inkSecondary)
                    .frame(width: 32, height: 32)
            }
            .disabled(isFirst)
            .opacity(isFirst ? 0.3 : 1)
            .accessibilityLabel("Back")
            Spacer(minLength: 0)
            progressDots
            Spacer(minLength: 0)
            Color.clear.frame(width: 32, height: 32)
        }
        .padding(.top, 6)
    }

    private var progressDots: some View {
        HStack(spacing: 6) {
            ForEach(pages.indices, id: \.self) { dot in
                Capsule()
                    .fill(dot == index ? Theme.jade : Theme.jade.opacity(0.22))
                    .frame(width: dot == index ? 20 : 7, height: 7)
                    .animation(.snappy(duration: 0.22), value: index)
            }
        }
    }

    private var pageCard: some View {
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
                TileRackView(tiles: page.tiles, tileWidth: 46)
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
            if isLast {
                recommendationCard
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .themedCard(corner: 22)
        .shine(trigger: shineTrigger, corner: 22)
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
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            index -= 1
        }
        fireShine()
    }

    private func advance() {
        if isLast {
            Haptics.success()
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
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
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
