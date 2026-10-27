import XCTest
@testable import MahjTrainer

/// No purchase starts while a reinstall's StoreKit sync is still working out
/// what this Apple Account owns, so a member is never sold Mahj+ again.
final class PurchaseGateTests: XCTestCase {
    func testNothingSellsUntilTheSyncSettles() {
        XCTAssertEqual(PurchaseGate.decide(isRecovering: true, lastRecovery: nil, isPro: false), .unsettled)
        XCTAssertEqual(PurchaseGate.decide(isRecovering: true, lastRecovery: .ownsNothing, isPro: true), .unsettled)
    }

    func testASettledSyncThatFoundAMemberSellsNothing() {
        XCTAssertEqual(PurchaseGate.decide(isRecovering: false, lastRecovery: .recovered, isPro: true), .alreadyMember)
    }

    /// StoreKit says the account owns Mahj+ but RevenueCat's sync failed:
    /// the app still reads it as free, and must not sell it a second plan.
    func testAnOwnerWhoseSyncFailedIsNotSold() {
        XCTAssertEqual(PurchaseGate.decide(isRecovering: false, lastRecovery: .ownedUnsynced, isPro: false), .unsettled)
    }

    /// A check that outlived its lifetime never answered: still no sale.
    func testAnUnresolvedCheckSellsNothing() {
        XCTAssertEqual(PurchaseGate.decide(isRecovering: false, lastRecovery: .unresolved, isPro: false), .unsettled)
    }

    /// RevenueCat's sync came back without an active Mahj+ entitlement while
    /// StoreKit says the account owns it: owned but unsynced, not recovered,
    /// and the sync is not marked done.
    func testASyncWithoutTheEntitlementIsNotARecovery() {
        var marked = false
        XCTAssertEqual(SubscriptionService.syncOutcome(entitled: false) { marked = true }, .ownedUnsynced)
        XCTAssertFalse(marked)
        XCTAssertEqual(SubscriptionService.syncOutcome(entitled: true) { marked = true }, .recovered)
        XCTAssertTrue(marked)
    }

    func testASettledStrangerCanBuy() {
        XCTAssertEqual(PurchaseGate.decide(isRecovering: false, lastRecovery: nil, isPro: false), .sell)
        XCTAssertEqual(PurchaseGate.decide(isRecovering: false, lastRecovery: .ownsNothing, isPro: false), .sell)
    }

    /// The free-week answer landing after the screen drew changes the terms,
    /// so the tap redraws instead of buying on the old ones.
    func testChangedTrialTermsNeedAnotherTap() {
        XCTAssertEqual(PurchaseTerms.check(shownTrial: true, offersTrial: false), .redraw)
        XCTAssertEqual(PurchaseTerms.check(shownTrial: false, offersTrial: true), .redraw)
        XCTAssertEqual(PurchaseTerms.check(shownTrial: true, offersTrial: true), .buy)
        XCTAssertEqual(PurchaseTerms.check(shownTrial: false, offersTrial: false), .buy)
    }
}

/// The membership check behind every purchase: one at a time, and nobody
/// waits on it for more than the timeout, the caller that starts it included.
@MainActor
final class MembershipRecoveryRunnerTests: XCTestCase {
    private var starts = 0

    func testTheCallerThatStartsAStalledCheckStillGetsItsTapBack() async {
        let runner = MembershipRecoveryRunner()
        let started = Date()
        await runner.run(timeout: 0.3) {
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            return .recovered
        }
        XCTAssertLessThan(Date().timeIntervalSince(started), 2)
        XCTAssertTrue(runner.isRunning, "the check keeps running past the deadline")
        XCTAssertNil(runner.last)
    }

    func testALaterCallerJoinsTheRunningCheck() async {
        let runner = MembershipRecoveryRunner()
        starts = 0
        let slow: @MainActor () async -> MembershipRecovery = { [self] in
            starts += 1
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            return .recovered
        }
        await runner.run(timeout: 0.1, slow)
        await runner.run(timeout: 0.1, slow)
        XCTAssertEqual(starts, 1)
    }

    func testAFinishedCheckReportsWhatItFound() async {
        let runner = MembershipRecoveryRunner()
        await runner.run(timeout: 5) { .ownedUnsynced }
        XCTAssertFalse(runner.isRunning)
        XCTAssertEqual(runner.last, .ownedUnsynced)
        await runner.run(timeout: 5) { .recovered }
        XCTAssertEqual(runner.last, .recovered)
    }
}

/// One rule for every purchase surface: the tap captures what the screen
/// showed, and Apple's sheet opens only if the live state still equals it.
final class PurchasePreflightTests: XCTestCase {
    private func intent(_ plan: PaywallPlan = .monthly, product: String? = "mahj.monthly",
                        price: String? = "$9.99", trial: Bool = true) -> PurchaseIntent {
        PurchaseIntent(plan: plan, productID: product, price: price, trial: trial)
    }

    private func decide(_ tapped: PurchaseIntent, _ live: PurchaseIntent, gate: PurchaseGate = .sell,
                        known: Bool = true) -> PreflightVerdict {
        PreflightVerdict.decide(intent: tapped, live: live, gate: gate, eligibilityKnown: known)
    }

    func testUnchangedTermsBuy() {
        XCTAssertEqual(decide(intent(), intent()), .buy)
    }

    /// Yearly tapped, Lifetime picked during the wait: the purchase is the
    /// captured plan's, and terms for any other plan never pass for it.
    func testTheCapturedPlanIsTheOneCompared() {
        let yearly = intent(.yearly, product: "mahj.yearly", price: "$39.99")
        let lifetime = intent(.lifetime, product: "mahj.lifetime", price: "$79.99")
        XCTAssertEqual(decide(yearly, lifetime), .redraw)
        XCTAssertEqual(decide(yearly, yearly), .buy)
    }

    /// A tap on "Loading price..." loads and redraws; it never buys, even
    /// once the products have arrived (3.1.2(c)).
    func testATapWithNoPriceOnScreenNeverBuys() {
        XCTAssertEqual(decide(intent(product: nil, price: nil), intent()), .redraw)
        XCTAssertEqual(decide(intent(price: nil), intent()), .redraw)
    }

    /// The comparison is against the trial wording captured at the tap, not
    /// whatever the screen's own state flipped to during the wait.
    func testALostFreeWeekRedraws() {
        XCTAssertEqual(decide(intent(trial: true), intent(trial: false)), .redraw)
        XCTAssertEqual(decide(intent(trial: false), intent(trial: true)), .redraw)
    }

    func testANewPriceRedraws() {
        XCTAssertEqual(decide(intent(price: "$9.99"), intent(price: "$12.99")), .redraw)
    }

    /// StoreKit's free-week answer did not come within the bound: no sale,
    /// the store reads as unreachable and a later tap tries again.
    func testUnknownEligibilityNeverBuysASubscription() {
        XCTAssertEqual(decide(intent(), intent(), known: false), .unavailable)
        let lifetime = intent(.lifetime, product: "mahj.lifetime", price: "$79.99")
        XCTAssertEqual(decide(lifetime, lifetime, known: false), .buy)
    }

    func testLifetimeCarriesNoTrial() {
        XCTAssertFalse(intent(.lifetime, trial: true).trial)
        XCTAssertEqual(intent(.lifetime, trial: true), intent(.lifetime, trial: false))
    }

    func testOwnershipComesFirst() {
        XCTAssertEqual(decide(intent(), intent(), gate: .unsettled), .unavailable)
        XCTAssertEqual(decide(intent(), intent(), gate: .alreadyMember), .alreadyMember)
    }

    func testAStoreWithoutTheProductSaysSo() {
        XCTAssertEqual(decide(intent(), intent(product: nil, price: nil)), .noProduct)
    }
}

@MainActor
final class MembershipRecoveryLifetimeTests: XCTestCase {
    private var clock = Date()
    private var starts = 0

    /// A stalled check is given up after its lifetime: it stops reading as
    /// running, its result (still a block) is `.unresolved`, the next tap
    /// starts a fresh check, and the stale one can never overwrite it.
    func testAStalledCheckExpiresAndTheNextTapStartsAnother() async {
        let runner = MembershipRecoveryRunner(lifetime: 10, now: { [unowned self] in clock })
        starts = 0
        await runner.run(timeout: 0.05) { [self] in
            starts += 1
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            return .recovered
        }
        XCTAssertTrue(runner.isRunning)
        clock = clock.addingTimeInterval(11)
        XCTAssertFalse(runner.isRunning)
        XCTAssertEqual(runner.last, .unresolved)
        XCTAssertEqual(PurchaseGate.decide(isRecovering: runner.isRunning, lastRecovery: runner.last, isPro: false), .unsettled)
        await runner.run(timeout: 5) { [self] in
            starts += 1
            return .ownsNothing
        }
        XCTAssertEqual(starts, 2)
        XCTAssertEqual(runner.last, .ownsNothing)
    }
}

/// A second identical challenge link is a new route with its own wait, so
/// Home has to see it even though the destination did not change.
@MainActor
final class PendingRouteIDTests: XCTestCase {
    func testIdenticalLinksAreSeparateRoutes() {
        let router = AppRouter()
        router.route(to: .monthlyChallenge)
        let first = router.pendingRouteID
        router.route(to: .monthlyChallenge)
        XCTAssertEqual(router.pendingRouteID, first + 1)
        XCTAssertFalse(router.pendingWaitIsOver)
    }
}
