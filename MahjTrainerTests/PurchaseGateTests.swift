import XCTest
@testable import MahjTrainer

/// No purchase starts while a reinstall's StoreKit sync is still working out
/// what this Apple Account owns, so a member is never sold Mahj+ again.
final class PurchaseGateTests: XCTestCase {
    func testNothingSellsUntilTheSyncSettles() {
        XCTAssertEqual(PurchaseGate.decide(isRecovering: true, isPro: false), .unsettled)
        XCTAssertEqual(PurchaseGate.decide(isRecovering: true, isPro: true), .unsettled)
    }

    func testASettledSyncThatFoundAMemberSellsNothing() {
        XCTAssertEqual(PurchaseGate.decide(isRecovering: false, isPro: true), .alreadyMember)
    }

    func testASettledStrangerCanBuy() {
        XCTAssertEqual(PurchaseGate.decide(isRecovering: false, isPro: false), .sell)
    }
}
