import SwiftUI
import RevenueCat

enum PaywallPlan: String, CaseIterable {
    case yearly, lifetime, monthly

    var ctaTitle: String {
        self == .lifetime ? "Unlock Forever" : "Start Free Trial"
    }
}

/// Shared paywall content used by the onboarding trial page and the
/// locked-room sheet. Falls back to static copy when RC isn't configured (sim).
struct PaywallContent: View {
    @EnvironmentObject private var subscriptions: SubscriptionService
    @Binding var selectedPlan: PaywallPlan

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("Unlock Every Room")
                    .font(Theme.display(30))
                    .foregroundStyle(Theme.ink)
                Text("The Card Room, Charleston Room, and Table Room, plus every drill added all year.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSecondary)
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
                .foregroundStyle(Theme.jade)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Theme.ink)
        }
    }

    private var planCards: some View {
        VStack(spacing: 10) {
            planCard(.yearly, title: "Yearly", price: price(for: .yearly) ?? "$9.99/year",
                     detail: "7 days free, then billed yearly", badge: "BEST VALUE")
            planCard(.lifetime, title: "Lifetime", price: price(for: .lifetime) ?? "$29.99",
                     detail: "Pay once, keep every room forever", badge: "NO SUBSCRIPTION")
            planCard(.monthly, title: "Monthly", price: price(for: .monthly) ?? "$1.99/month",
                     detail: "7 days free, then billed monthly", badge: nil)
        }
    }

    private func price(for plan: PaywallPlan) -> String? {
        guard let package = subscriptions.package(for: plan) else { return nil }
        let base = package.storeProduct.localizedPriceString
        switch plan {
        case .yearly: return "\(base)/year"
        case .monthly: return "\(base)/month"
        case .lifetime: return base
        }
    }

    private func planCard(_ plan: PaywallPlan, title: String, price: String, detail: String, badge: String?) -> some View {
        let isSelected = selectedPlan == plan
        return Button {
            selectedPlan = plan
            Haptics.impact(.light, intensity: 0.6)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(Theme.ink)
                        if let badge {
                            Text(badge)
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Theme.gold.opacity(0.18), in: Capsule())
                                .foregroundStyle(Theme.gold)
                        }
                    }
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(Theme.inkSecondary)
                }
                Spacer()
                Text(price)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.ink)
            }
            .padding(14)
            .background(
                isSelected ? Theme.jade.opacity(0.08) : Theme.card,
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(isSelected ? Theme.jade : Theme.rule, lineWidth: isSelected ? 2 : 1)
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
                                Text(selectedPlan.ctaTitle)
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
                        .foregroundStyle(Theme.inkSecondary)
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
        .foregroundStyle(Theme.inkSecondary)
    }

    private func purchase() {
        purchasing = true
        Task {
            defer { purchasing = false }
            do {
                try await subscriptions.purchase(subscriptions.package(for: selectedPlan))
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
