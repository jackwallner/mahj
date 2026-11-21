import XCTest
@testable import MahjTrainer

/// B8: a cached non-member record is not a lapse.
extension LowBugRegressionTests {
    // MARK: B8 a cached non-member record is not a lapse

    func testACachedExpiredRecordNeverStartsADepartureQuestionForARenewingMember() {
        let defaults = freshDefaults("LowBugChurnCache")
        let service = SubscriptionService.shared
        service.consumeChurnMoment()
        defer { service.consumeChurnMoment() }
        let renewing = MembershipSnapshot(isActive: true, isTrial: false, willRenew: true)
        let now = Date()
        service.observe(renewing, answeredAt: now, now: now, defaults: defaults)
        // Cold launch: RevenueCat's cache, four days old, reads as expired.
        service.observe(.none, answeredAt: now.addingTimeInterval(-4 * 86_400), now: now, defaults: defaults)
        XCTAssertNil(service.pendingChurnMoment)
        // The network then says the member is active, as it renewed.
        service.observe(renewing, answeredAt: now, now: now, defaults: defaults)
        XCTAssertNil(service.pendingChurnMoment)
    }

    func testARealLapseIsStillCaughtWhenTheNetworkConfirmsIt() {
        let defaults = freshDefaults("LowBugChurnReal")
        let service = SubscriptionService.shared
        service.consumeChurnMoment()
        defer { service.consumeChurnMoment() }
        let renewing = MembershipSnapshot(isActive: true, isTrial: false, willRenew: true)
        let now = Date()
        service.observe(renewing, answeredAt: now, now: now, defaults: defaults)
        service.observe(.none, answeredAt: now.addingTimeInterval(-4 * 86_400), now: now, defaults: defaults)
        XCTAssertNil(service.pendingChurnMoment)
        service.observe(.none, answeredAt: now, now: now, defaults: defaults)
        XCTAssertEqual(service.pendingChurnMoment, .paidLapsed)
    }
}
