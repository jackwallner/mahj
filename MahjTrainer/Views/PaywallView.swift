import SwiftUI
import RevenueCat

enum PaywallPlan: String, CaseIterable {
    case yearly, lifetime, monthly

    var ctaTitle: String {
        self == .lifetime ? "Unlock \(Membership.name) Forever" : "Start 7-Day Free Trial"
    }
}

enum PaywallLinks {
    /// Apple's standard EULA. If the app ever ships a custom EULA, this is the
    /// one place to swap it; App Review requires a functional Terms link here.
    static let terms = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let privacy = URL(string: "https://jackwallner.github.io/mahj/privacy-policy")!
    static let manageSubscriptions = URL(string: "https://apps.apple.com/account/subscriptions")!
}

/// Shared paywall content used by the locked-drill sheet and Settings.
///
/// App Review 3.1.2 wants all of this ON the purchase screen, not buried:
/// the membership name, what each plan costs, the billing period, an explicit
/// auto-renew statement, Restore, and working Terms + Privacy links. Every one
/// of those lives in this file; don't trim them for layout.
struct PaywallContent: View {
    @EnvironmentObject private var subscriptions: SubscriptionService
    @Binding var selectedPlan: PaywallPlan

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 6) {
                Text("Get \(Membership.name)")
                    .font(Theme.display(28))
                    .foregroundStyle(Theme.ink)
                Text("Everything you have stays free. \(Membership.name) adds a smarter practice rhythm that never runs out.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSecondary)
                    .multilineTextAlignment(.center)
            }
            // Leads with the endless modes on purpose. Selling "more drills"
            // is what let a motivated player finish the membership in two
            // sittings; what they are actually buying now is practice that
            // does not end.
            VStack(alignment: .leading, spacing: 9) {
                benefit("Mahj Minute: the shared five-question daily challenge")
                benefit("Game Night Prep: five minutes built around your weak spots")
                benefit("Endless Practice: a fresh rack dealt every time")
                benefit("Fix My Mistakes: misses come back until they stick")
                benefit("Timed Challenge: 90 seconds, chase your best")
                benefit("Extra practice sets in every room, plus the Master Tables")
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
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var planCards: some View {
        VStack(spacing: 10) {
            planCard(.yearly, title: "Yearly", price: PaywallPricing.priceText(subscriptions, .yearly),
                     perMonth: PaywallPricing.perMonthEquivalent(subscriptions),
                     detail: "7 days free, then billed yearly. Auto-renews.", badge: "BEST VALUE")
            planCard(.lifetime, title: "Lifetime", price: PaywallPricing.priceText(subscriptions, .lifetime),
                     perMonth: nil,
                     detail: "One payment. No subscription, nothing renews.", badge: "NO SUBSCRIPTION")
            planCard(.monthly, title: "Monthly", price: PaywallPricing.priceText(subscriptions, .monthly),
                     perMonth: nil,
                     detail: "7 days free, then billed monthly. Auto-renews.", badge: nil)
        }
    }

    private func planCard(_ plan: PaywallPlan, title: String, price: String, perMonth: String?,
                          detail: String, badge: String?) -> some View {
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
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 1) {
                    Text(price)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.ink)
                    if let perMonth {
                        Text(perMonth)
                            .font(.caption2)
                            .foregroundStyle(Theme.inkSecondary)
                    }
                }
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

/// Price and terms strings, live from StoreKit.
///
/// Hardcoded fallback amounts used to live here, and they had already drifted a
/// full price tier out of date, so the screen could quietly quote $19.99/year on
/// a $9.99 product. A price the store did not give us is worse than no price at
/// all (3.1.2 wants the amount the customer will actually be charged), so an
/// unresolved product renders the loading placeholder and the disclosure drops
/// the amount rather than inventing one.
@MainActor
enum PaywallPricing {
    /// Shown in the amount's place until StoreKit answers.
    static let placeholder = "Loading price…"

    /// The localized billed amount, or nil while the product is still in flight.
    static func price(_ subscriptions: SubscriptionService, _ plan: PaywallPlan) -> String? {
        guard let base = subscriptions.package(for: plan)?.storeProduct.localizedPriceString else {
            return nil
        }
        switch plan {
        case .yearly: return "\(base)/year"
        case .monthly: return "\(base)/month"
        case .lifetime: return base
        }
    }

    /// The same, ready to render: the amount or the placeholder.
    static func priceText(_ subscriptions: SubscriptionService, _ plan: PaywallPlan) -> String {
        price(subscriptions, plan) ?? placeholder
    }

    /// Yearly billed amount restated per month, e.g. "$3.33/mo". Yearly is the
    /// only plan this makes sense for; everything else returns nil.
    ///
    /// This is the line that keeps a yearly price legible next to the monthly
    /// one. Without it a 4x sticker gap reads as a penalty instead of a saving.
    static func perMonthEquivalent(_ subscriptions: SubscriptionService) -> String? {
        guard let product = subscriptions.package(for: .yearly)?.storeProduct else { return nil }
        let monthly = product.price / 12
        let fmt = NumberFormatter()
        fmt.numberStyle = .currency
        fmt.locale = product.priceFormatter?.locale ?? .current
        guard let text = fmt.string(from: monthly as NSDecimalNumber) else { return nil }
        return "\(text)/mo"
    }

    /// One concise point-of-purchase line: price, trial, auto-renew, cancel.
    /// The full legalese lives in the EULA behind the Terms link.
    static func terms(_ subscriptions: SubscriptionService, _ plan: PaywallPlan) -> String {
        guard let amount = price(subscriptions, plan) else {
            switch plan {
            case .lifetime:
                return "One-time purchase. Not a subscription, nothing renews."
            case .yearly, .monthly:
                return "Includes 7 days free. Auto-renews until canceled."
            }
        }
        switch plan {
        case .lifetime:
            return "\(amount) one-time. Not a subscription, nothing renews."
        case .yearly, .monthly:
            return "7 days free, then \(amount). Auto-renews until canceled."
        }
    }
}

/// Standalone paywall sheet (locked drills, locked rooms, Settings upgrade).
struct PaywallView: View {
    @EnvironmentObject private var subscriptions: SubscriptionService
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: PaywallPlan = .yearly
    @State private var purchasing = false
    @State private var restoring = false
    @State private var message: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                PaywallContent(selectedPlan: $selectedPlan)
                    .padding()
                    .frame(maxWidth: 680)
                    .frame(maxWidth: .infinity)
            }
            .background(Theme.background)
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 8) {
                    Text(PaywallPricing.terms(subscriptions, selectedPlan))
                        .font(.caption)
                        .foregroundStyle(Theme.inkSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
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
            .alert("Mahj Trainer", isPresented: .init(
                get: { message != nil },
                set: { if !$0 { message = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(message ?? "")
            }
            .onChange(of: subscriptions.isPro) { _, isPro in
                if isPro { dismiss() }
            }
        }
    }

    private var footerLinks: some View {
        HStack(spacing: 16) {
            Button("Restore") { restore() }
                .disabled(restoring)
            Link("Terms of Use", destination: PaywallLinks.terms)
            Link("Privacy Policy", destination: PaywallLinks.privacy)
        }
        .font(.caption)
        .foregroundStyle(Theme.inkSecondary)
    }

    private func purchase() {
        purchasing = true
        Task {
            defer { purchasing = false }
            do {
                await subscriptions.ensureOfferings()
                let outcome = try await subscriptions.purchase(subscriptions.package(for: selectedPlan))
                guard outcome == .purchased else { return }
                Haptics.success()
                // The sheet dismisses itself the moment `isPro` flips. If the
                // entitlement hasn't landed after a few seconds, say so and
                // point at Restore, rather than leaving someone who just paid
                // looking at the paywall that charged them.
                if await !subscriptions.confirmEntitlement() {
                    message = "Your purchase went through, but \(Membership.name) hasn't unlocked yet. Give it a moment, then tap Restore. You will not be charged twice."
                }
            } catch {
                // A cancel never lands here (it's an outcome, not a throw), so
                // anything that does is worth telling the player about.
                message = error.localizedDescription
            }
        }
    }

    private func restore() {
        restoring = true
        Task {
            defer { restoring = false }
            do {
                try await subscriptions.restore()
                if !subscriptions.isPro {
                    message = "No previous purchase found on this Apple Account."
                }
            } catch {
                message = error.localizedDescription
            }
        }
    }
}
