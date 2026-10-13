import SwiftUI

/// Shown once, right after a free trial starts: one notification, two days
/// before the trial ends, chosen rather than imposed.
///
/// The fear behind most day-zero trial cancellations is forgetting and being
/// charged. Offering the reminder up front answers that fear with a promise
/// the app keeps, which is worth more than any feature on the trial page.
struct TrialReminderOfferView: View {
    let onAccept: () -> Void
    let onDecline: () -> Void

    @State private var busy = false

    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(Theme.jade)
                .frame(width: 92, height: 92)
                .background(Theme.jade.opacity(0.12), in: Circle())
            Text("Want a heads-up before the trial ends?")
                .font(Theme.display(30))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text("One notification, two days before your free week is up. Keep \(Membership.name) and nothing changes. Not for you? There's time to cancel and you won't be charged.")
                .font(.body)
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Spacer()
            VStack(spacing: 10) {
                Button {
                    guard !busy else { return }
                    busy = true
                    Haptics.impact(.light, intensity: 0.6)
                    onAccept()
                } label: {
                    Group {
                        if busy {
                            ProgressView().tint(Theme.onFill)
                        } else {
                            Text("Remind me 2 days before")
                        }
                    }
                    .primaryCTA()
                }
                Button {
                    onDecline()
                } label: {
                    Text("No thanks")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.inkSecondary)
                        .frame(height: 30)
                }
                .disabled(busy)
            }
            .padding(.bottom, 10)
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: Theme.readableContentWidth)
        .frame(maxWidth: .infinity)
        .background(Theme.background)
    }
}
