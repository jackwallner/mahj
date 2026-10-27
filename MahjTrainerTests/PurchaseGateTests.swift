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
