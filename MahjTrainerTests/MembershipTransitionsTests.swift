import XCTest
@testable import MahjTrainer

final class MembershipTransitionsTests: XCTestCase {
    private let trialOn = MembershipSnapshot(isActive: true, isTrial: true, willRenew: true)
    private let trialOff = MembershipSnapshot(isActive: true, isTrial: true, willRenew: false)
    private let paidOn = MembershipSnapshot(isActive: true, isTrial: false, willRenew: true)
    private let paidOff = MembershipSnapshot(isActive: true, isTrial: false, willRenew: false)
    private let gone = MembershipSnapshot.none

    func testFirstObservationIsNeverAMoment() {
        XCTAssertNil(MembershipTransitions.churnMoment(from: nil, to: gone))
        XCTAssertNil(MembershipTransitions.churnMoment(from: nil, to: trialOff))
    }

    func testTrialTurningRenewalOff() {
        XCTAssertEqual(MembershipTransitions.churnMoment(from: trialOn, to: trialOff), .trialRenewalOff)
    }

    func testPaidTurningRenewalOff() {
        XCTAssertEqual(MembershipTransitions.churnMoment(from: paidOn, to: paidOff), .paidRenewalOff)
    }

    func testTrialLapsing() {
        XCTAssertEqual(MembershipTransitions.churnMoment(from: trialOn, to: gone), .trialLapsed)
        XCTAssertEqual(MembershipTransitions.churnMoment(from: trialOff, to: gone), .trialLapsed)
    }

    func testPaidLapsing() {
        XCTAssertEqual(MembershipTransitions.churnMoment(from: paidOff, to: gone), .paidLapsed)
    }

    func testTrialConvertingIsNotAMoment() {
        XCTAssertNil(MembershipTransitions.churnMoment(from: trialOn, to: paidOn))
    }

    func testStayingGoneIsNotAMoment() {
        XCTAssertNil(MembershipTransitions.churnMoment(from: gone, to: gone))
    }

    func testTurningRenewalBackOnIsNotAMoment() {
        XCTAssertNil(MembershipTransitions.churnMoment(from: paidOff, to: paidOn))
    }

    func testComingBackResetsTheAsk() {
        XCTAssertTrue(MembershipTransitions.resetsAsk(from: paidOff, to: paidOn))
        XCTAssertTrue(MembershipTransitions.resetsAsk(from: gone, to: trialOn))
        XCTAssertFalse(MembershipTransitions.resetsAsk(from: paidOn, to: paidOn))
        XCTAssertFalse(MembershipTransitions.resetsAsk(from: nil, to: paidOn))
    }

    @MainActor
    func testServiceRemembersOneMomentPerDeparture() {
        let defaults = UserDefaults(suiteName: "MembershipTransitionsTests")!
        defaults.removePersistentDomain(forName: "MembershipTransitionsTests")
        let service = SubscriptionService.shared
        service.consumeChurnMoment()

        service.observe(trialOn, defaults: defaults)
        XCTAssertNil(service.pendingChurnMoment)
        service.observe(trialOff, defaults: defaults)
        XCTAssertEqual(service.pendingChurnMoment, .trialRenewalOff)

        // Shown, then the trial lapses: no second question for the same exit.
        service.consumeChurnMoment()
        service.observe(gone, defaults: defaults)
        XCTAssertNil(service.pendingChurnMoment)

        // They come back and leave again later: a fresh ask.
        service.observe(paidOn, defaults: defaults)
        service.observe(paidOff, defaults: defaults)
        XCTAssertEqual(service.pendingChurnMoment, .paidRenewalOff)
        service.consumeChurnMoment()
    }

    /// Monthly to lifetime is an upgrade, not a departure. Lifetime reports
    /// willRenew false with no expiration date.
    func testUpgradingToLifetimeIsNotAChurnMoment() {
        let monthly = MembershipSnapshot.observed(isActive: true, isTrial: false, willRenew: true, expirationDate: Date())
        let lifetime = MembershipSnapshot.observed(isActive: true, isTrial: false, willRenew: false, expirationDate: nil)
        XCTAssertTrue(lifetime.willRenew)
        XCTAssertNil(MembershipTransitions.churnMoment(from: monthly, to: lifetime))
    }

    func testCancelledSubscriptionStillReadsAsRenewalOff() {
        let on = MembershipSnapshot.observed(isActive: true, isTrial: false, willRenew: true, expirationDate: Date())
        let off = MembershipSnapshot.observed(isActive: true, isTrial: false, willRenew: false, expirationDate: Date())
        XCTAssertEqual(MembershipTransitions.churnMoment(from: on, to: off), .paidRenewalOff)
    }
}
