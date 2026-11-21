import RevenueCat
import XCTest
@testable import MahjTrainer

final class PurchaseErrorCopyTests: XCTestCase {
    /// Ask to Buy: RevenueCat's pending error reads as waiting, not failure.
    func testAskToBuyIsShownAsWaitingForApproval() {
        let shown = PurchaseError.shown(RevenueCat.ErrorCode.paymentPendingError)
        XCTAssertEqual(shown as? PurchaseError, .waitingForApproval)
        XCTAssertEqual(shown.localizedDescription, String(localized: "Waiting for approval. Your purchase unlocks once it is approved."))
        XCTAssertFalse(shown.localizedDescription.contains("pending"))
    }

    func testOtherErrorsPassThroughUntouched() {
        let other = RevenueCat.ErrorCode.purchaseNotAllowedError
        XCTAssertEqual((PurchaseError.shown(other) as? RevenueCat.ErrorCode), other)
        XCTAssertEqual(PurchaseError.shown(RevenueCat.ErrorCode.networkError) as? PurchaseError, .productsUnavailable)
        XCTAssertEqual(PurchaseError.shown(RevenueCat.ErrorCode.offlineConnectionError) as? PurchaseError, .productsUnavailable)
        XCTAssertEqual(PurchaseError.shown(PurchaseError.productsUnavailable) as? PurchaseError, .productsUnavailable)
    }

    /// StoreKit owns Mahj+ but RevenueCat's sync returned nothing: the copy
    /// says to Restore, and a stalled or running check keeps the connection copy.
    func testOwnedButUnsyncedPointsAtRestoreAndNotAtTheConnection() {
        XCTAssertEqual(PurchaseError.unavailable(isRecovering: false, lastRecovery: .ownedUnsynced), .foundOnAccount)
        XCTAssertEqual(PurchaseError.unavailable(isRecovering: false, lastRecovery: .unresolved), .productsUnavailable)
        XCTAssertEqual(PurchaseError.unavailable(isRecovering: true, lastRecovery: .ownedUnsynced), .productsUnavailable)
        XCTAssertEqual(PurchaseError.unavailable(isRecovering: false, lastRecovery: nil), .productsUnavailable)
        XCTAssertTrue(PurchaseError.foundOnAccount.localizedDescription.contains("Restore"))
        XCTAssertFalse(PurchaseError.foundOnAccount.localizedDescription.contains("connection"))
    }
}
