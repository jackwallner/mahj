import SwiftUI
import RevenueCat

enum PaywallPlan: String, CaseIterable {
    case yearly, monthly
}

/// Shared paywall content used by the onboarding trial page and the
/// locked-room sheet. Falls back to static copy when RC isn't configured (sim).
struct PaywallContent: View {
    @EnvironmentObject private var subscriptions: SubscriptionService
    @Binding var selectedPlan: PaywallPlan

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 8) {
                Text("Unlock Every Room")
                    .font(.title.bold())
                Text("The Card Room, Charleston Room, and Table Room, plus every drill added all year.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            VStack(alignment: .leading, spacing: 10) {
                benefit("Read any rack and name its section")
                benefit("Practice the Charleston without the panic")
                benefit("Keep-or-throw instincts for real games")
                benefit("New drills as skills grow")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            planCards
        }
    }

    private func benefit(_ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Theme.felt)
            Text(text)
                .font(.subheadline)
        }
    }

    private var planCards: some View {
        VStack(spacing: 10) {
            planCard(.yearly, title: "Yearly", price: price(for: .yearly) ?? "$29.99/year",
                     detail: "7 days free, then billed yearly", badge: "BEST VALUE")
            planCard(.monthly, title: "Monthly", price: price(for: .monthly) ?? "$4.99/month",
                     detail: "7 days free, then billed monthly", badge: nil)
        }
    }

    private func price(for plan: PaywallPlan) -> String? {
        guard let offering = subscriptions.offerings?.current else { return nil }
        let package = plan == .yearly ? offering.annual : offering.monthly
        guard let package else { return nil }
        let unit = plan == .yearly ? "year" : "month"
        return "\(package.storeProduct.localizedPriceString)/\(unit)"
    }

    private func planCard(_ plan: PaywallPlan, title: String, price: String, detail: String, badge: String?) -> some View {
        let isSelected = selectedPlan == plan
        return Button {
            selectedPlan = plan
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(title).font(.headline)
                        if let badge {
                            Text(badge)
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Theme.gold.opacity(0.2), in: Capsule())
                                .foregroundStyle(Theme.gold)
                        }
                    }
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(price)
                    .font(.subheadline.weight(.semibold))
            }
            .padding(14)
            .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(isSelected ? Theme.felt : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

/// Standalone paywall sheet (locked rooms, Settings upgrade).
struct PaywallView: View {
    @EnvironmentObject private var subscriptions: SubscriptionService
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: PaywallPlan = .yearly
    @State private var purchasing = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                PaywallContent(selectedPlan: $selectedPlan)
                    .padding()
            }
            .background(Theme.background)
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 8) {
                    Button {
                        purchase()
                    } label: {
                        Group {
                            if purchasing {
                                ProgressView().tint(.white)
                            } else {
                                Text("Start Free Trial")
                            }
                        }
                        .primaryCTA()
                    }
                    .disabled(purchasing)
                    footerLinks
                }
                .padding()
                .background(.thinMaterial)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("Purchase Issue", isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
            .onChange(of: subscriptions.isPro) { _, isPro in
                if isPro { dismiss() }
            }
        }
    }

    private var footerLinks: some View {
        HStack(spacing: 16) {
            Button("Restore") {
                Task { try? await subscriptions.restore() }
            }
            Link("Terms", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
            Link("Privacy", destination: URL(string: "https://jackwallner.github.io/mahj/privacy-policy")!)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private func purchase() {
        purchasing = true
        Task {
            defer { purchasing = false }
            do {
                if let offering = subscriptions.offerings?.current,
                   let package = selectedPlan == .yearly ? offering.annual : offering.monthly {
                    try await subscriptions.purchase(package)
                } else {
                    // Sim / RC not configured: SubscriptionService flips the local override.
                    try await subscriptions.purchase(nil)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
