import SwiftUI

/// The Mahj+ card under a finished practice, for players who are not members.
/// Jack (2026-10-19): every results screen pitches. 56 of 57 trials began on
/// the onboarding page, so a player who said "not yet" there never heard about
/// Mahj+ again. A quiet card the player taps, never a sheet on its own; the
/// screen owns the sheet so its rating ask can wait while the paywall is up.
struct MahjPlusPitchCard: View {
    let headline: String
    let detail: String
    let action: () -> Void

    @EnvironmentObject private var subscriptions: SubscriptionService
    @EnvironmentObject private var progress: ProgressStore
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(
        headline: String = "Try \(Membership.name) free for 7 days",
        detail: String = "Play coached practice hands as often as you want, with fresh racks that never run out.",
        action: @escaping () -> Void
    ) {
        self.headline = headline
        self.detail = detail
        self.action = action
    }

    /// Members never see it, and neither does the onboarding tour, whose
    /// flow is frozen.
    static func isShown(subscriptions: SubscriptionService, progress: ProgressStore) -> Bool {
        !subscriptions.isPro && progress.hasOnboarded
    }

    var body: some View {
        if Self.isShown(subscriptions: subscriptions, progress: progress) {
            Button(action: action) {
                Group {
                    if dynamicTypeSize.isAccessibilitySize {
                        VStack(alignment: .leading, spacing: 8) {
                            icon
                            text
                        }
                    } else {
                        HStack(spacing: 12) {
                            icon
                            text
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
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Theme.gold.opacity(0.45), lineWidth: 1)
            )
            .accessibilityHint("Shows \(Membership.name) plans")
        }
    }

    private var icon: some View {
        Image(systemName: "sparkles")
            .font(.body.weight(.semibold))
            .foregroundStyle(Theme.gold)
            .frame(width: 38, height: 38)
            .background(Theme.gold.opacity(0.14), in: Circle())
            .accessibilityHidden(true)
    }

    private var text: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(headline)
                .font(.headline)
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            Text(detail)
                .font(.caption)
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
