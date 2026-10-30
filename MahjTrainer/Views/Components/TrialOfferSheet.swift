import SwiftUI

/// What the player just did, so the sheet's headline answers it.
enum TrialOfferContext {
    case drillResult
    case minuteResult
    case handSpent

    var headline: String {
        switch self {
        case .drillResult: return String(localized: "Keep the practice going")
        case .minuteResult: return String(localized: "Want more than five a day?")
        case .handSpent: return String(localized: "Play another hand now")
        }
    }

    /// RevenueCat impression id. Auto and tapped asks are reported apart so
    /// the two can be compared.
    func source(auto: Bool) -> String {
        let base: String
        switch self {
        case .drillResult: base = "mahj_offer_drill"
        case .minuteResult: base = "mahj_offer_minute"
        case .handSpent: base = "mahj_offer_hand"
        }
        return auto ? "\(base)_auto" : base
    }
}

/// The one-tap trial ask after a practice, Vitals' pattern: a short sheet with
/// one plan and one button that goes straight to Apple's confirm sheet. The
/// plan is the onboarding page's (`onboarding_plan`, monthly by default), so
/// both one-tap asks buy the same thing. It carries every 3.1.2 element the
/// onboarding page does: membership name, billed amount as the largest price
/// text, the auto-renew line, Terms, Privacy and Restore.
struct TrialOfferSheet: View {
    let context: TrialOfferContext
    let auto: Bool

    @EnvironmentObject private var subscriptions: SubscriptionService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var purchasing = false
    @State private var restoring = false
    @State private var message: String?
    @State private var showPlans = false
    @State private var height: CGFloat = 520
    /// Picked once, so a metadata refresh never swaps the body mid-read.
    @State private var pitch: OfferPitch?
    /// The tap's preflight and purchase; cancelled if the sheet goes away.
    @State private var purchaseTask: Task<Void, Never>?

    static let benefits = [
        String(localized: "Play coached practice hands, as many as you want"),
        String(localized: "Fresh racks and passes that never run out"),
        String(localized: "Your misses come back until they stick"),
    ]

    private var plan: PaywallPlan { subscriptions.onboardingPlan.plan }

    /// False once StoreKit says this Apple Account already had its free week:
    /// the sheet then states the price billed today and promises no trial.
    /// The service's answer, so the sheet and the purchase check read the
    /// same value.
    private var trialEligible: Bool { subscriptions.offersTrial }

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                ScrollView { content }
                    .presentationDetents([.large])
            } else {
                // The sheet as designed while it fits. Taller than the screen
                // (an SE at XXXL), the detent stops at full height and the
                // legal row fell off the bottom; there the content scrolls.
                ViewThatFits(in: .vertical) {
                    measuredContent
                    ScrollView { measuredContent }
                        .scrollBounceBehavior(.basedOnSize)
                }
                .presentationDetents([.height(height)])
            }
        }
        .presentationDragIndicator(.visible)
        .presentationBackground(Theme.background)
        .interactiveDismissDisabled(purchasing)
        .alert("Mahj Trainer", isPresented: .init(
            get: { message != nil },
            set: { if !$0 { message = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(message ?? "")
        }
        .sheet(isPresented: $showPlans) { PaywallView(source: context.source(auto: auto)) }
        .onChange(of: subscriptions.isPro) { _, isPro in
            if isPro { dismiss() }
        }
        .onDisappear { purchaseTask?.cancel() }
        .task {
            let shown = pitch ?? subscriptions.offerPitch
            pitch = shown
            if PaywallPricing.price(subscriptions, plan) == nil {
                await subscriptions.loadOfferings()
            } else {
                await subscriptions.refreshTrialEligibility()
            }
            // Before the impression, which syncs it to RevenueCat with the
            // view. A lapsed member sees neither pitch but keeps an arm; the
            // coin is independent of eligibility, so both arms dilute alike.
            UserDefaults.standard.set(shown.rawValue, forKey: OfferPitch.armKey)
            subscriptions.trackPaywallImpression(id: context.source(auto: auto))
        }
    }

    private var measuredContent: some View {
        content
            .fixedSize(horizontal: false, vertical: true)
            .onGeometryChangeCompat { height = $0 }
    }

    private var content: some View {
        VStack(spacing: 18) {
            Image(systemName: "sparkles")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(Theme.gold)
                .frame(width: 60, height: 60)
                .background(Theme.gold.opacity(0.14), in: Circle())
                .accessibilityHidden(true)
            VStack(spacing: 6) {
                Text(context.headline)
                    .font(Theme.display(26))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Text(trialEligible ? String(localized: "Try \(Membership.name) free for 7 days.") : String(localized: "Everything in \(Membership.name), starting today."))
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSecondary)
                    .multilineTextAlignment(.center)
            }
            if trialEligible, (pitch ?? subscriptions.offerPitch) == .timeline {
                timeline
            } else {
                benefitList
            }
            VStack(spacing: 2) {
                Text(PaywallPricing.priceText(subscriptions, plan))
                    .font(Theme.display(22))
                    .foregroundStyle(Theme.ink)
                Text(PaywallPricing.terms(subscriptions, plan, trial: trialEligible))
                    .font(.caption2)
                    .foregroundStyle(Theme.inkTertiary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            VStack(spacing: 6) {
                Button(action: startTrial) {
                    Group {
                        if purchasing {
                            ProgressView().tint(Theme.onFill)
                        } else {
                            Text(trialEligible ? subscriptions.trialCTA(.onboarding) : String(localized: "Join \(Membership.name)"))
                        }
                    }
                    .primaryCTA()
                }
                .disabled(purchasing || restoring)
                Button("Not now") { dismiss() }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.inkSecondary)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                    .disabled(purchasing)
            }
            legalRow
        }
        .padding(.horizontal, 24)
        .padding(.top, 28)
        .padding(.bottom, 12)
        .frame(maxWidth: 520)
        .frame(maxWidth: .infinity)
    }

    private var benefitList: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Self.benefits, id: \.self) { line in
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.jade)
                        .accessibilityHidden(true)
                    Text(line)
                        .font(.subheadline)
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// How the free week runs, with real dates. "Cancel by" is the day before
    /// the trial ends: Apple renews unless canceled at least 24 hours ahead.
    private var timeline: some View {
        let ends = Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now
        let cancelBy = Calendar.current.date(byAdding: .day, value: -1, to: ends) ?? ends
        let day = Date.FormatStyle().month(.abbreviated).day()
        return VStack(alignment: .leading, spacing: 12) {
            timelineRow("lock.open.fill", String(localized: "Today"), String(localized: "All of \(Membership.name) opens: coached practice hands, fresh racks, Fix My Mistakes"))
            timelineRow("calendar", String(localized: "By \(cancelBy.formatted(day))"), String(localized: "Cancel in Settings and you pay nothing"))
            timelineRow("star.fill", ends.formatted(day), plan == .yearly
                ? String(localized: "Your yearly plan begins")
                : String(localized: "Your monthly plan begins"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func timelineRow(_ icon: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Theme.jade)
                .frame(width: 22)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var legalRow: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 8))
            : AnyLayout(HStackLayout(spacing: 14))
        // 44pt targets, as on the paywall; the drawn text does not move.
        // Stacked at accessibility sizes, where the text alone is tall enough.
        let hit = dynamicTypeSize.isAccessibilitySize ? EdgeInsets() : EdgeInsets(top: 10, leading: 6, bottom: 21, trailing: 6)
        return layout {
            Link(destination: PaywallLinks.terms) { Text("Terms").hitPadding(hit) }
                .padding(-hit)
            Link(destination: PaywallLinks.privacy) { Text("Privacy").hitPadding(hit) }
                .padding(-hit)
            Button(action: restore) { Text("Restore").hitPadding(hit) }
                .padding(-hit)
                .disabled(purchasing || restoring)
        }
        .font(.caption2)
        .foregroundStyle(Theme.inkTertiary)
    }

    /// Straight to Apple's confirm sheet, as on the onboarding page. Backing
    /// out of Apple's sheet is the player saying no to Apple, not to the app:
    /// stay put. The plan picker is only for products that failed to load.
    private func startTrial() {
        purchasing = true
        // What the sheet shows at this tap; the purchase runs on exactly that.
        let intent = subscriptions.intent(for: plan, trialShown: trialEligible)
        purchaseTask = Task {
            defer { purchasing = false }
            do {
                // One bounded preflight, then Apple's sheet only if the terms
                // still hold. A tap on "Loading price...", or on a free week
                // StoreKit just said is gone, redraws for another tap.
                switch try await subscriptions.buy(intent) {
                case .redraw, .bought(.cancelled):
                    break
                case .noProduct:
                    showPlans = true
                case .bought(.alreadyMember):
                    dismiss()
                case .bought(.purchased):
                    if await subscriptions.confirmEntitlement() {
                        dismiss()
                    } else {
                        message = String(localized: "Your purchase went through, but \(Membership.name) hasn't unlocked yet. Give it a moment, then tap Restore.")
                    }
                }
            } catch is CancellationError {
                return
            } catch {
                message = error.localizedDescription
            }
        }
    }

    private func restore() {
        guard !restoring, !purchasing else { return }
        restoring = true
        Task {
            defer { restoring = false }
            do {
                try await subscriptions.restore()
                if !subscriptions.isPro {
                    message = String(localized: "No previous purchase found on this Apple Account.")
                }
            } catch {
                message = error.localizedDescription
            }
        }
    }
}

extension View {
    /// The one-tap trial sheet for a result screen. Bump `autoMoment` at a
    /// good result; the sheet then rises on its own if `TrialOfferPacer`
    /// allows. Setting `isPresented` (a tapped Mahj+ card) always opens it.
    func trialOffer(_ context: TrialOfferContext, isPresented: Binding<Bool>, autoMoment: Int) -> some View {
        modifier(TrialOfferModifier(context: context, isPresented: isPresented, autoMoment: autoMoment))
    }

    /// Reports the view's height; `onGeometryChange` itself is iOS 18.
    fileprivate func onGeometryChangeCompat(_ action: @escaping (CGFloat) -> Void) -> some View {
        background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear { action(proxy.size.height) }
                    .onChange(of: proxy.size.height) { _, new in action(new) }
            }
        )
    }
}

private struct TrialOfferModifier: ViewModifier {
    let context: TrialOfferContext
    @Binding var isPresented: Bool
    let autoMoment: Int

    @EnvironmentObject private var subscriptions: SubscriptionService
    @EnvironmentObject private var progress: ProgressStore
    @State private var onScreen = false
    @State private var auto = false

    func body(content: Content) -> some View {
        content
            .onAppear { onScreen = true }
            .onDisappear { onScreen = false }
            .onChange(of: autoMoment) { _, _ in schedule() }
            .onChange(of: isPresented) { _, shown in if !shown { auto = false } }
            .sheet(isPresented: $isPresented) { TrialOfferSheet(context: context, auto: auto) }
    }

    private func schedule() {
        guard eligible else { return }
        Task { @MainActor in
            // Let the result land before anything rises over it.
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            guard onScreen, !isPresented, eligible else { return }
            // Never rise on its own to promise a free week Apple won't give.
            guard await subscriptions.isTrialEligible(for: subscriptions.onboardingPlan.plan),
                  onScreen, !isPresented else { return }
            TrialOfferPacer.markAutoShown(installedAt: ConversionDiagnostics.installDate)
            auto = true
            isPresented = true
        }
    }

    private var eligible: Bool {
        !subscriptions.isPro && progress.hasOnboarded && subscriptions.isOn(.trialOffer)
            && TrialOfferPacer.autoOfferDue(
                practicesSinceOnboarding: progress.totalSessions - progress.sessionsAtOnboarding,
                installedAt: ConversionDiagnostics.installDate
            )
    }
}
