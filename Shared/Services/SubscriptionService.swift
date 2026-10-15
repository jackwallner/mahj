import Foundation
import RevenueCat
import StoreKit

enum RevenueCatConfig {
    #if DEBUG
    static let apiKey = "test_KqPmoSpYxqBfWQAdVjZVspTYdMe"
    #else
    static let apiKey = "appl_BPcKRTMgnvYJJaNPXdfGReCkHgO"
    #endif
}

/// What actually happened at Apple's sheet. A cancel is an outcome, not an error.
enum PurchaseOutcome: Sendable {
    case purchased
    case cancelled
}

enum PurchaseError: LocalizedError {
    case productsUnavailable

    var errorDescription: String? {
        "The App Store isn't reachable right now. Check your connection and try again."
    }
}

struct PaywallPrice {
    let amount: Decimal
    let localized: String
    let locale: Locale
}

@MainActor
final class SubscriptionService: NSObject, ObservableObject {
    static let shared = SubscriptionService()

    @Published private(set) var isPro = false
    /// False until a customer record has actually been read, from
    /// RevenueCat's on-device cache or the network. `isPro` is false before
    /// that for members too, so nothing may treat "not a member" as a lapse,
    /// or sell a member a trial, until this is true.
    @Published private(set) var membershipResolved = false
    /// The active entitlement is the free week (RevenueCat `periodType`), not a
    /// paid or lifetime membership.
    @Published private(set) var isTrialing = false
    /// When the current entitlement ends: the trial's real end while trialing.
    @Published private(set) var expirationDate: Date?
    @Published private(set) var offerings: Offerings?
    /// Apple's answer to "would this Apple Account get the free week on this
    /// plan?", per subscription plan. One introductory offer per subscription
    /// group per Apple Account, ever, so anyone who has trialled monthly or
    /// yearly before is charged on day one. Missing means not known yet.
    @Published private(set) var introEligibility: [PaywallPlan: IntroEligibilityStatus] = [:]
    /// Set when a trial or membership was just seen turning toward the exit,
    /// and not yet asked about. Home presents the one-question prompt and
    /// clears it. Survives a launch: the ask is stored, not just published.
    @Published private(set) var pendingChurnMoment: ChurnMoment?

    private var isConfigured = false
    private let localOverrideKey = "subscription.localProOverride"
    private let snapshotKey = "membership.lastSnapshot"
    /// How old a customer record may be and still serve as the first baseline.
    static let freshBaselineAge: TimeInterval = 300
    private let churnAskSpentKey = "membership.churnAskSpent"
    private let pendingChurnKey = "membership.pendingChurnMoment"
    private let reinstallSyncKey = "membership.reinstallSyncDone"
    private var paywallImpressionsThisSession: Set<String> = []
    private var isRecoveringMembership = false

    override private init() {
        super.init()
        isPro = UserDefaults.standard.bool(forKey: localOverrideKey)
        pendingChurnMoment = UserDefaults.standard.string(forKey: pendingChurnKey)
            .flatMap(ChurnMoment.init(rawValue:))
    }

    /// The churn prompt was shown (or dismissed). One ask per departure.
    func consumeChurnMoment() {
        pendingChurnMoment = nil
        UserDefaults.standard.removeObject(forKey: pendingChurnKey)
    }

    func start() {
        configureIfNeeded()
        guard isConfigured else {
            // No store at all (simulator, screenshots): nothing will ever
            // load, so what we have is the answer.
            membershipResolved = true
            return
        }
        // The last record RevenueCat saw, from the first frame: a member is a
        // member before the network answers.
        if let cached = Purchases.shared.cachedCustomerInfo { apply(cached) }
        Task {
            await refreshCustomerInfo()
            // In parallel with offerings: a reinstalled member should be
            // recognised before the trial page can be reached.
            async let recovered: Void = recoverReinstalledMembershipIfNeeded()
            await loadOfferings()
            await recovered
        }
    }

    /// Whether the purchase surfaces may promise the free week for `plan`.
    ///
    /// Only on Apple's own "eligible". Ineligible, no offer, or not known yet
    /// all get plain pricing (RevenueCat's guidance for unknown): telling a
    /// returning subscriber "7 days free" and then charging them on day one
    /// is the bait-and-switch 3.1.2(a) forbids, and a refund request.
    func offersFreeTrial(_ plan: PaywallPlan) -> Bool {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-mahj.previewTrialEligible") { return plan != .lifetime }
        #endif
        return Self.offersFreeTrial(plan, eligibility: introEligibility[plan])
    }

    nonisolated static func offersFreeTrial(_ plan: PaywallPlan, eligibility: IntroEligibilityStatus?) -> Bool {
        plan != .lifetime && eligibility == .eligible
    }

    /// Asks StoreKit (through RevenueCat) which subscription plans would
    /// start with the free week for this Apple Account. On-device, no
    /// RevenueCat request; RevenueCat caches the answer and clears it whenever
    /// the customer record changes, so it is asked again then.
    func refreshIntroEligibility() async {
        guard isConfigured else { return }
        let plans: [PaywallPlan] = [.monthly, .yearly]
        let products = plans.compactMap { plan in package(for: plan).map { (plan, $0.storeProduct) } }
        guard !products.isEmpty else { return }
        var answers: [PaywallPlan: IntroEligibilityStatus] = [:]
        for (plan, product) in products {
            answers[plan] = await Purchases.shared.checkTrialOrIntroDiscountEligibility(product: product)
        }
        introEligibility = answers
    }

    /// A reinstall is a new anonymous RevenueCat user, and iOS does not bring
    /// an existing subscription across on its own, so a paying member looked
    /// like a stranger (and was offered a trial) until they found Restore.
    /// StoreKit already knows what this Apple Account owns: if it holds a
    /// current entitlement and RevenueCat does not, sync once per install.
    /// `syncPurchases` never shows an Apple Account sign-in prompt.
    ///
    /// Retried (from `ensureOfferings`, so before any purchase) until one sync
    /// succeeds: a failed sync on a bad network must not lose it for good.
    func recoverReinstalledMembershipIfNeeded() async {
        guard isConfigured, !isPro, !isRecoveringMembership,
              !UserDefaults.standard.bool(forKey: reinstallSyncKey) else { return }
        isRecoveringMembership = true
        defer { isRecoveringMembership = false }
        var ownsSomething = false
        for await result in Transaction.currentEntitlements {
            if case .verified = result {
                ownsSomething = true
                break
            }
        }
        guard ownsSomething else { return }
        guard let info = try? await Purchases.shared.syncPurchases() else { return }
        UserDefaults.standard.set(true, forKey: reinstallSyncKey)
        apply(info)
    }

    /// Dev/testing switch: flips Pro without a live RC key (Settings toggle).
    func setLocalOverride(isPro: Bool) {
        UserDefaults.standard.set(isPro, forKey: localOverrideKey)
        self.isPro = isPro
    }

    private func configureIfNeeded() {
        guard !isConfigured else { return }
        #if targetEnvironment(simulator)
        #if DEBUG
        // The one simulator path allowed to configure RevenueCat, and only ever
        // with the Test Store key: a separate RevenueCat app inside the same
        // project, so a probe run cannot touch App Store customers, revenue or
        // charts. See RevenueCatProbe.
        if RevenueCatProbe.isEnabled {
            Purchases.logLevel = .debug
            Purchases.configure(
                with: Configuration.Builder(withAPIKey: RevenueCatProbe.testStoreKey)
                    .with(appUserID: RevenueCatProbe.appUserID)
                    .build()
            )
            Purchases.shared.delegate = self
            isConfigured = true
            return
        }
        #endif
        guard RevenueCatConfig.apiKey.hasPrefix("test_") else { return }
        #endif
        guard !RevenueCatConfig.apiKey.contains("PLACEHOLDER") else { return }
        #if DEBUG
        Purchases.logLevel = .debug
        #endif
        Purchases.configure(withAPIKey: RevenueCatConfig.apiKey)
        Purchases.shared.delegate = self
        // Standard Apple Ads attribution (no ATT prompt): RevenueCat learns which
        // campaign and keyword drove an install, so ad cohorts can be judged on
        // trials and revenue instead of installs alone.
        Purchases.shared.attribution.enableAdServicesAttributionTokenCollection()
        isConfigured = true
    }

    /// Feeds RevenueCat's `paywall_encounter_v3`. A custom paywall emits no
    /// events of its own, so without this call everything between "installed"
    /// and "started a trial" is invisible for this app.
    func trackPaywallImpression(id: String, oncePerSession: Bool = false) {
        guard isConfigured else { return }
        if oncePerSession {
            guard !paywallImpressionsThisSession.contains(id) else { return }
            paywallImpressionsThisSession.insert(id)
        }
        ConversionDiagnostics.recordPitchView(impressionID: id)
        syncConversionAttributes()
        Purchases.shared.trackCustomPaywallImpression(
            CustomPaywallImpressionParams(paywallId: id)
        )
    }

    /// Mirrors the on-device paywall record onto the RevenueCat customer.
    ///
    /// Attributes rather than extra impressions: RevenueCat treats every
    /// impression id as a paywall encounter, so funnel steps sent that way would
    /// drive the encounter rate to 100% and destroy the one server-side number
    /// that currently works.
    ///
    /// `isConfigured` is the load-bearing guard: `Purchases.shared` traps when
    /// RevenueCat was never configured, which is every simulator run.
    func syncConversionAttributes() {
        guard isConfigured else { return }
        var attributes = ConversionDiagnostics.subscriberAttributes
        guard !attributes.isEmpty else { return }
        if let offering = offerings?.current?.identifier {
            attributes["offering_id"] = offering
        }
        // `setAttributes` only queues. RevenueCat uploads the queue when the app
        // backgrounds, or folds it into the POST that creates a customer, and a
        // customer-info fetch does NOT flush it (measured, not assumed). That is
        // fine in production, where every session ends in a backgrounding, but it
        // means a probe run has to background the app before reading anything
        // back.
        Purchases.shared.attribution.setAttributes(attributes)
    }

    /// `fetchCurrent` when the answer has to be new (right after a purchase):
    /// the default policy hands back a cached record for five minutes, so a
    /// "confirm" loop on it re-read the same stale record three times.
    func refreshCustomerInfo(fetchCurrent: Bool = false) async {
        guard isConfigured else { return }
        let policy: CacheFetchPolicy = fetchCurrent ? .fetchCurrent : .cachedOrFetched
        if let info = try? await Purchases.shared.customerInfo(fetchPolicy: policy) {
            apply(info)
        }
    }

    func loadOfferings() async {
        guard isConfigured else { return }
        offerings = try? await Purchases.shared.offerings()
        await refreshIntroEligibility()
    }

    func package(for plan: PaywallPlan) -> Package? {
        guard let offering = offerings?.current else { return nil }
        switch plan {
        case .yearly: return offering.annual
        case .monthly: return offering.monthly
        case .lifetime: return offering.lifetime
        }
    }

    func paywallPrice(for plan: PaywallPlan) -> PaywallPrice? {
        guard let product = package(for: plan)?.storeProduct else { return nil }
        return PaywallPrice(
            amount: product.price,
            localized: product.localizedPriceString,
            locale: product.priceFormatter?.locale ?? .current
        )
    }

    /// Offerings can still be in flight when a player reaches the trial CTA on
    /// a cold, slow network. Give them one more chance to land before we call
    /// the products missing, so the button isn't dead on a fast tapper.
    @discardableResult
    func ensureOfferings() async -> Bool {
        guard isConfigured else { return false }
        await recoverReinstalledMembershipIfNeeded()
        if introEligibility.isEmpty, offerings?.current != nil { await refreshIntroEligibility() }
        if offerings?.current != nil { return true }
        await loadOfferings()
        return offerings?.current != nil
    }

    func purchase(_ package: Package?) async throws -> PurchaseOutcome {
        guard isConfigured else {
            throw PurchaseError.productsUnavailable
        }
        guard let package else { throw PurchaseError.productsUnavailable }
        let result = try await Purchases.shared.purchase(package: package)
        // RevenueCat reports a user backing out of Apple's sheet as a normal
        // result, not an error. Treating it as a failure is what used to shove
        // a second paywall in front of someone who just said "not now".
        if result.userCancelled { return .cancelled }
        apply(result.customerInfo)
        // What Apple actually sold, not what the product offers: a returning
        // subscriber buying a plan with a trial is charged on day one.
        let startedTrial = result.customerInfo.entitlements["pro"]?.periodType == .trial
        ConversionDiagnostics.recordConversion(
            plan: package.storeProduct.productIdentifier,
            startedTrial: startedTrial,
            offeringID: package.presentedOfferingContext.offeringIdentifier
        )
        syncConversionAttributes()
        return .purchased
    }

    /// StoreKit says the money moved; RevenueCat's entitlement can take a beat
    /// to catch up. Poll briefly rather than leave someone who just paid
    /// staring at the paywall that took their money.
    @discardableResult
    func confirmEntitlement(attempts: Int = 3) async -> Bool {
        guard isConfigured else { return isPro }
        for attempt in 0..<attempts {
            await refreshCustomerInfo(fetchCurrent: true)
            if isPro { return true }
            if attempt < attempts - 1 {
                try? await Task.sleep(nanoseconds: 1_200_000_000)
            }
        }
        return isPro
    }

    func restore() async throws {
        guard isConfigured else { return }
        let info = try await Purchases.shared.restorePurchases()
        apply(info)
    }

    private func apply(_ info: CustomerInfo) {
        let entitlement = info.entitlements["pro"]
        let entitled = entitlement?.isActive == true
        let override = UserDefaults.standard.bool(forKey: localOverrideKey)
        isPro = entitled || override
        membershipResolved = true
        isTrialing = entitled && entitlement?.periodType == .trial
        expirationDate = entitled ? entitlement?.expirationDate : nil
        // The trial-end reminder promises "keep it and nothing changes". Once
        // the trial has converted, been switched off, or ended, that is no
        // longer true, so it must not fire.
        if !(isTrialing && entitlement?.willRenew == true) {
            AppSettings.cancelTrialEndReminder()
        }
        observe(MembershipSnapshot.observed(
            isActive: entitled,
            isTrial: entitlement?.periodType == .trial,
            willRenew: entitlement?.willRenew == true,
            expirationDate: entitlement?.expirationDate
        ), answeredAt: info.requestDate)
    }

    /// Compares this customer record with the last one seen and remembers a
    /// churn moment, once per departure. Both snapshots come from RevenueCat,
    /// never from the local override, so a debug toggle cannot fake a lapse.
    ///
    /// The first record ever seen becomes the baseline only if RevenueCat
    /// answered it recently. Launch applies the cached record first, which
    /// can be months old: a member who lapsed on an older build read as
    /// active there, then lapsed a second later, and was asked why they were
    /// leaving about a departure the app never watched.
    func observe(
        _ current: MembershipSnapshot,
        answeredAt: Date = Date(),
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) {
        let previous = (defaults.data(forKey: snapshotKey))
            .flatMap { try? JSONDecoder().decode(MembershipSnapshot.self, from: $0) }
        if previous == nil, now.timeIntervalSince(answeredAt) > Self.freshBaselineAge { return }
        defer {
            if let data = try? JSONEncoder().encode(current) {
                defaults.set(data, forKey: snapshotKey)
            }
        }
        if MembershipTransitions.resetsAsk(from: previous, to: current) {
            defaults.removeObject(forKey: churnAskSpentKey)
        }
        guard pendingChurnMoment == nil, !defaults.bool(forKey: churnAskSpentKey) else { return }
        guard let moment = MembershipTransitions.churnMoment(from: previous, to: current) else { return }
        defaults.set(true, forKey: churnAskSpentKey)
        defaults.set(moment.rawValue, forKey: pendingChurnKey)
        pendingChurnMoment = moment
    }
}

extension SubscriptionService: PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            self.apply(customerInfo)
            // RevenueCat drops its eligibility cache on every customer change.
            await self.refreshIntroEligibility()
        }
    }
}

#if DEBUG
/// Simulator-only proof path for the fleet-wide funnel attributes.
///
/// Under the normal rules the attributes cannot be verified on a simulator: the
/// production key must never be configured there, so RevenueCat is never
/// configured, so nothing is ever sent, so a physical device is the only
/// witness. The Test Store key is a different RevenueCat app inside the same
/// project, so a probe run cannot touch App Store customers, revenue or charts.
///
/// DEBUG only, and only with the launch argument, so it cannot reach a Release
/// build or an ordinary simulator run.
enum RevenueCatProbe {
    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains("-rcfunnelprobe")
    }

    static let testStoreKey = "test_KqPmoSpYxqBfWQAdVjZVspTYdMe"

    static var appUserID: String {
        ProcessInfo.processInfo.environment["RC_PROBE_USER"] ?? "funnel-probe-mahj"
    }

    static var impressionID: String {
        ProcessInfo.processInfo.environment["RC_PROBE_SURFACE"] ?? "mahj_onboarding_trial"
    }

    /// Also run a purchase against the Test Store, so the `converted_*` half of
    /// the record is exercised and not just the impression half.
    ///
    /// Test Store purchases are simulated by RevenueCat and never touch StoreKit
    /// or the App Store, so this creates no revenue and no real transaction.
    /// Only some projects have Test Store packages configured; the ones with an
    /// empty Test Store offering cannot run this.
    static var wantsPurchase: Bool {
        ProcessInfo.processInfo.arguments.contains("-rcfunnelprobepurchase")
    }
}
#endif
