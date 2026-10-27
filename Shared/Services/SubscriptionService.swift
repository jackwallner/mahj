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
enum PurchaseOutcome: Equatable, Sendable {
    case purchased
    case cancelled
    /// A reinstall's StoreKit sync found this Apple Account already owns
    /// Mahj+, so nothing was sold.
    case alreadyMember
}

/// What a reinstall's membership check found.
enum MembershipRecovery: Equatable, Sendable {
    /// StoreKit holds no current entitlement for this Apple Account.
    case ownsNothing
    /// RevenueCat synced what StoreKit holds.
    case recovered
    /// StoreKit holds an entitlement but RevenueCat's sync failed, or
    /// synced without an active Mahj+ entitlement, so the account owns Mahj+
    /// while the app still reads it as free.
    case ownedUnsynced
    /// The check outlived its lifetime without an answer. Ownership is still
    /// unknown, so nothing is sold; the next tap starts a fresh check.
    case unresolved
}

/// What `purchase` may do while a reinstall's membership sync runs.
enum PurchaseGate: Equatable, Sendable {
    case sell
    case alreadyMember
    /// The sync has not settled, or StoreKit says the account already owns
    /// Mahj+ and RevenueCat has not caught up: selling now could charge a
    /// member for a second plan.
    case unsettled

    static func decide(isRecovering: Bool, lastRecovery: MembershipRecovery?, isPro: Bool) -> PurchaseGate {
        if isRecovering { return .unsettled }
        if isPro { return .alreadyMember }
        switch lastRecovery {
        case .ownedUnsynced, .unresolved: return .unsettled
        case .ownsNothing, .recovered, nil: return .sell
        }
    }
}

/// What the screen showed when the player tapped buy: the plan, its product,
/// the price drawn and the trial wording. A purchase runs only on exactly
/// these terms. Lifetime has no free week, so its `trial` is always false.
struct PurchaseIntent: Equatable, Sendable {
    let plan: PaywallPlan
    let productID: String?
    /// nil when the screen showed "Loading price..." instead of an amount.
    let price: String?
    let trial: Bool

    init(plan: PaywallPlan, productID: String?, price: String?, trial: Bool) {
        self.plan = plan
        self.productID = productID
        self.price = price
        self.trial = plan == .lifetime ? false : trial
    }
}

/// The one preflight rule, applied after one bounded wait: buy only when the
/// live state still equals what the player tapped on; otherwise redraw and
/// ask for another tap.
enum PreflightVerdict: Equatable, Sendable {
    case buy
    /// The screen's terms are stale (no price drawn, a new price, a lost free
    /// week, another plan): it redraws and nothing is bought.
    case redraw
    case alreadyMember
    /// Ownership or the free-week answer did not settle in time: the store
    /// reads as unreachable, and a later tap tries again.
    case unavailable
    /// The store answered without this plan's product.
    case noProduct

    static func decide(
        intent: PurchaseIntent,
        live: PurchaseIntent,
        gate: PurchaseGate,
        eligibilityKnown: Bool
    ) -> PreflightVerdict {
        switch gate {
        case .alreadyMember: return .alreadyMember
        case .unsettled: return .unavailable
        case .sell: break
        }
        guard live.productID != nil, live.price != nil else { return .noProduct }
        guard intent.plan == .lifetime || eligibilityKnown else { return .unavailable }
        // A tap on "Loading price..." never buys: the price has to be on
        // screen first (3.1.2(c)).
        guard intent.price != nil else { return .redraw }
        return live == intent ? .buy : .redraw
    }
}

/// Whether a purchase may run on the terms the screen showed. The free-week
/// answer can land after the screen drew; then the screen redraws with the
/// real terms and the player taps again.
enum PurchaseTerms: Equatable, Sendable {
    case buy
    case redraw

    static func check(shownTrial: Bool, offersTrial: Bool) -> PurchaseTerms {
        offersTrial == shownTrial ? .buy : .redraw
    }
}

/// Runs one membership check at a time. Every caller, the one that starts it
/// included, waits at most `timeout`; the check keeps running past that, and
/// the next caller waits on the same one instead of starting another. A check
/// older than `lifetime` is given up (`last` = `.unresolved`, which still
/// blocks sales) and the next caller starts a fresh one, so one stalled sync
/// cannot fail every later tap.
@MainActor
final class MembershipRecoveryRunner {
    private var task: Task<Void, Never>?
    private var attempt = 0
    private var startedAt: Date?
    private(set) var last: MembershipRecovery?
    let lifetime: TimeInterval
    private let now: () -> Date

    init(lifetime: TimeInterval = 15, now: @escaping () -> Date = Date.init) {
        self.lifetime = lifetime
        self.now = now
    }

    var isRunning: Bool {
        expireIfStale()
        return task != nil
    }

    func run(timeout: TimeInterval, _ work: @escaping @MainActor () async -> MembershipRecovery) async {
        expireIfStale()
        if task == nil {
            attempt += 1
            let mine = attempt
            startedAt = now()
            task = Task { @MainActor in
                let result = await work()
                // A check given up on must not overwrite a newer one.
                guard mine == self.attempt else { return }
                self.last = result
                self.task = nil
                self.startedAt = nil
            }
        }
        // Poll rather than await the task: an await on it cannot be cut
        // short, and a task group waits for every child before it returns.
        let deadline = Date().addingTimeInterval(timeout)
        while task != nil, Date() < deadline, !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
    }

    private func expireIfStale() {
        guard task != nil, let startedAt, now().timeIntervalSince(startedAt) >= lifetime else { return }
        task?.cancel()
        task = nil
        self.startedAt = nil
        attempt += 1
        last = .unresolved
    }
}

/// What a tap on buy came to.
enum PurchaseAttempt: Equatable, Sendable {
    case bought(PurchaseOutcome)
    /// The terms on screen were stale; nothing was bought.
    case redraw
    /// The store answered without the plan's product.
    case noProduct
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
    /// Set when a trial or membership was just seen turning toward the exit,
    /// and not yet asked about. Home presents the one-question prompt and
    /// clears it. Survives a launch: the ask is stored, not just published.
    @Published private(set) var pendingChurnMoment: ChurnMoment?
    /// StoreKit says this Apple Account already had its free week (one per
    /// subscription group), so it is charged on day one. False until
    /// StoreKit answers: unknown reads as eligible, as 1.3.2 assumed, so an
    /// eligible player's trial page and paywall stay exactly 1.3.2's.
    @Published private(set) var trialIneligible = false

    private var isConfigured = false
    private let localOverrideKey = "subscription.localProOverride"
    private let snapshotKey = "membership.lastSnapshot"
    /// How old a customer record may be and still serve as the first baseline.
    static let freshBaselineAge: TimeInterval = 300
    private let churnAskSpentKey = "membership.churnAskSpent"
    private let pendingChurnKey = "membership.pendingChurnMoment"
    private let reinstallSyncKey = "membership.reinstallSyncDone"
    private var paywallImpressionsThisSession: Set<String> = []
    private let membershipRecovery = MembershipRecoveryRunner()
    /// StoreKit's free-week answer for this account: nil until StoreKit has
    /// answered about a real product, and again whenever offerings reload.
    private var trialEligibility: Bool?
    private var eligibilityTask: Task<Void, Never>?
    /// Bumped on every offerings load, so an answer about the old products
    /// cannot land on the new ones.
    private var offeringsGeneration = 0
    /// How long a tap waits on StoreKit, for the membership check and the
    /// free-week answer alike.
    static let preflightTimeout: TimeInterval = 3

    override private init() {
        super.init()
        isPro = UserDefaults.standard.bool(forKey: localOverrideKey)
        #if DEBUG
        // Captures: `-mahj.trialIneligible YES` shows an account without a free week.
        trialIneligible = UserDefaults.standard.bool(forKey: "mahj.trialIneligible")
        #endif
        pendingChurnMoment = UserDefaults.standard.string(forKey: pendingChurnKey)
            .flatMap(ChurnMoment.init(rawValue:))
    }

    /// The offering's metadata (the remote switches) is known: loaded, or
    /// there is no store to ask at all (simulator, screenshots).
    var remoteConfigKnown: Bool { offerings != nil || !isConfigured }

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

    /// A reinstall is a new anonymous RevenueCat user, and iOS does not bring
    /// an existing subscription across on its own, so a paying member looked
    /// like a stranger (and was offered a trial) until they found Restore.
    /// StoreKit already knows what this Apple Account owns: if it holds a
    /// current entitlement and RevenueCat does not, sync once per install.
    /// `syncPurchases` never shows an Apple Account sign-in prompt.
    ///
    /// Retried (from `ensureOfferings`, so before any purchase) until one sync
    /// succeeds: a failed sync on a bad network must not lose it for good.
    /// A second caller (the trial button) waits for a sync already running
    /// instead of skipping it, so a slow sync cannot let a member be sold,
    /// but never holds the button more than a few seconds on a stalled one.
    /// A reinstall's StoreKit sync is still running. The one-tap sheet will
    /// not sell until it knows what this Apple Account already owns.
    var isRecoveringMembership: Bool { membershipRecovery.isRunning }

    /// Whether this Apple Account still gets the plan's free week. Apple gives
    /// an introductory offer once per subscription group, so a lapsed member
    /// is charged on day one. No product to ask about (offerings not loaded,
    /// no RevenueCat on a simulator) reads as eligible, as 1.3.2 assumed.
    func isTrialEligible(for plan: PaywallPlan) async -> Bool {
        await Self.isTrialEligible(package(for: plan)?.storeProduct.sk2Product)
    }

    nonisolated static func isTrialEligible(_ product: Product?) async -> Bool {
        guard let subscription = product?.subscription else { return true }
        guard subscription.introductoryOffer != nil else { return false }
        return await subscription.isEligibleForIntroOffer
    }

    /// Starts the check if it is needed, or joins one already running, and
    /// waits at most 3s either way: a stalled sync must not hold a purchase
    /// spinner for good. The check itself keeps going.
    func recoverReinstalledMembershipIfNeeded() async {
        let needed = isConfigured && !isPro && !UserDefaults.standard.bool(forKey: reinstallSyncKey)
        guard needed || membershipRecovery.isRunning else { return }
        await membershipRecovery.run(timeout: 3) { [weak self] in
            await self?.recoverReinstalledMembership() ?? .ownsNothing
        }
    }

    private func recoverReinstalledMembership() async -> MembershipRecovery {
        var ownsSomething = false
        for await result in Transaction.currentEntitlements {
            if case .verified = result {
                ownsSomething = true
                break
            }
        }
        guard ownsSomething else { return .ownsNothing }
        // A failed sync is not "owns nothing": StoreKit just said this
        // account owns Mahj+, so nothing may be sold until a sync succeeds.
        guard let info = try? await Purchases.shared.syncPurchases() else { return .ownedUnsynced }
        apply(info)
        return Self.syncOutcome(entitled: info.entitlements["pro"]?.isActive == true, markSynced: {
            UserDefaults.standard.set(true, forKey: reinstallSyncKey)
        })
    }

    /// A sync that returns without an active Mahj+ entitlement has not
    /// recovered anything: StoreKit still says the account owns it, so it
    /// stays owned-but-unsynced (no sale) and the sync runs again next time.
    nonisolated static func syncOutcome(entitled: Bool, markSynced: () -> Void) -> MembershipRecovery {
        guard entitled else { return .ownedUnsynced }
        markSynced()
        return .recovered
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
        var configuration = Configuration.Builder(withAPIKey: RevenueCatConfig.apiKey)
        // Test Store runs share one tester instead of a fresh anonymous customer
        // per install, so test installs don't inflate the live project's
        // customer charts. Never with the App Store key.
        if RevenueCatConfig.apiKey.hasPrefix("test_") {
            configuration = configuration.with(
                appUserID: ProcessInfo.processInfo.environment["RC_APP_USER_ID"] ?? "qa-ios"
            )
        }
        Purchases.configure(with: configuration.build())
        Purchases.shared.delegate = self
        // Standard Apple Ads attribution (no ATT prompt): RevenueCat learns which
        // campaign and keyword drove an install, so ad cohorts can be judged on
        // trials and revenue instead of installs alone.
        Purchases.shared.attribution.enableAdServicesAttributionTokenCollection()
        // Meta ad measurement, off until the build carries a Meta app id.
        MetaAds.linkRevenueCat()
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
        // Which trial page variants this customer saw (`RemoteConfig`), for
        // reading an Experiment by attribute as well as by offering.
        attributes.merge(remoteVariantAttributes) { _, new in new }
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
        let loaded = try? await Purchases.shared.offerings()
        offerings = loaded
        offeringsGeneration += 1
        trialEligibility = nil
        eligibilityTask?.cancel()
        eligibilityTask = nil
        await refreshTrialEligibility()
    }

    /// Both plans share one subscription group, so the onboarding plan's
    /// answer is the paywall's too. Waits at most `timeout` on StoreKit and
    /// returns whether the answer is known. No product, no answer: a failed
    /// offerings fetch must not pass for "eligible".
    @discardableResult
    func refreshTrialEligibility(timeout: TimeInterval = SubscriptionService.preflightTimeout) async -> Bool {
        if trialEligibility != nil { return true }
        guard let package = package(for: onboardingPlan.plan) else { return false }
        if eligibilityTask == nil {
            let generation = offeringsGeneration
            let product = package.storeProduct.sk2Product
            eligibilityTask = Task { @MainActor in
                let eligible = await Self.isTrialEligible(product)
                guard generation == self.offeringsGeneration, !Task.isCancelled else { return }
                self.trialEligibility = eligible
                if self.trialIneligible == eligible { self.trialIneligible = !eligible }
                self.eligibilityTask = nil
            }
        }
        let deadline = Date().addingTimeInterval(timeout)
        while trialEligibility == nil, eligibilityTask != nil, Date() < deadline, !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
        return trialEligibility != nil
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
        if offerings?.current == nil { await loadOfferings() }
        // Offerings publish before StoreKit's free-week answer: a tap in
        // between must not buy under trial wording the account cannot get.
        if offerings?.current != nil { await refreshTrialEligibility() }
        return offerings?.current != nil
    }

    /// Whether a purchase may run on the trial terms the screen showed.
    func purchaseTerms(shownTrial: Bool) -> PurchaseTerms {
        PurchaseTerms.check(shownTrial: shownTrial, offersTrial: !trialIneligible)
    }

    /// What a purchase screen is showing for `plan` right now. Screens call
    /// this at the tap, with the trial wording they drew.
    func intent(for plan: PaywallPlan, trialShown: Bool) -> PurchaseIntent {
        let product = package(for: plan)?.storeProduct
        return PurchaseIntent(
            plan: plan,
            productID: product?.productIdentifier,
            price: product?.localizedPriceString,
            trial: trialShown
        )
    }

    /// The one preflight every purchase surface runs after the tap: settle
    /// ownership, load the products, get StoreKit's free-week answer, each
    /// bounded, then compare the live terms with the tapped ones.
    func preflight(_ intent: PurchaseIntent) async -> PreflightVerdict {
        // No store at all: the same as a store without the product.
        guard isConfigured else { return .noProduct }
        await recoverReinstalledMembershipIfNeeded()
        if offerings?.current == nil || package(for: intent.plan) == nil { await loadOfferings() }
        let eligibilityKnown = await refreshTrialEligibility()
        return PreflightVerdict.decide(
            intent: intent,
            live: self.intent(for: intent.plan, trialShown: offersTrial),
            gate: PurchaseGate.decide(isRecovering: isRecoveringMembership, lastRecovery: membershipRecovery.last, isPro: isPro),
            eligibilityKnown: eligibilityKnown
        )
    }

    /// Preflight, then buy exactly the tapped plan if its terms still hold.
    /// `.redraw` means nothing was bought and the screen now shows the live
    /// terms; the player taps again. Throws `productsUnavailable` when the
    /// store did not settle in time, and `CancellationError` when the screen
    /// went away during the wait.
    func buy(_ intent: PurchaseIntent) async throws -> PurchaseAttempt {
        switch await preflight(intent) {
        case .buy: break
        case .redraw: return .redraw
        case .alreadyMember: return .bought(.alreadyMember)
        case .unavailable: throw PurchaseError.productsUnavailable
        case .noProduct: return .noProduct
        }
        return .bought(try await purchase(package(for: intent.plan)))
    }

    func purchase(_ package: Package?) async throws -> PurchaseOutcome {
        guard isConfigured else {
            throw PurchaseError.productsUnavailable
        }
        guard let package else { throw PurchaseError.productsUnavailable }
        // Every purchase surface goes through here, so this is the one place
        // that makes sure a reinstall's StoreKit sync has settled first. A
        // sync still stalled after the wait reads as the store being
        // unreachable, which it is.
        await recoverReinstalledMembershipIfNeeded()
        switch PurchaseGate.decide(isRecovering: isRecoveringMembership, lastRecovery: membershipRecovery.last, isPro: isPro) {
        case .sell: break
        case .alreadyMember: return .alreadyMember
        case .unsettled: throw PurchaseError.productsUnavailable
        }
        // The screen may have gone away during the preflight (Close, a swipe
        // down): nothing may reach Apple's sheet for a screen nobody sees.
        try Task.checkCancellation()
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
        // The tracking prompt follows a trial or a purchase, and nothing
        // else: Meta only counts a trial whose owner allowed tracking.
        MetaAds.notePurchase()
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
            // A card problem turns willRenew off too, but nobody chose to
            // leave: Apple is still retrying, so it is not a churn moment.
            willRenew: entitlement?.willRenew == true || entitlement?.billingIssueDetectedAt != nil,
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
            // They came back before Home asked: a queued "why are you
            // leaving?" is now false, so drop it.
            pendingChurnMoment = nil
            defaults.removeObject(forKey: pendingChurnKey)
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
