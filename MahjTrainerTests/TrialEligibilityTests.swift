import StoreKit
import StoreKitTest
import XCTest
@testable import MahjTrainer

/// The one-tap sheet only promises a free week when StoreKit says this Apple
/// Account still has one. Runs against the app's StoreKit fixture, so no
/// RevenueCat, no sandbox account and no real purchase.
final class TrialEligibilityTests: XCTestCase {
    private var session: SKTestSession!

    override func setUpWithError() throws {
        let fixture = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("MahjTrainer/MahjTrainer.storekit")
        session = try SKTestSession(contentsOf: fixture)
        session.resetToDefaultState()
        session.clearTransactions()
        session.disableDialogs = true
    }

    override func tearDown() {
        session?.clearTransactions()
        session = nil
        super.tearDown()
    }

    private func product(_ id: String) async throws -> Product {
        let products = try await Product.products(for: [id])
        return try XCTUnwrap(products.first, "\(id) missing from the fixture")
    }

    /// StoreKit caches the answer on each `Product`, so the lapsed check uses
    /// freshly fetched products. Real lapsed members are fine: their history
    /// predates the launch. The purchase goes through the app
    /// (`Product.purchase`); `SKTestSession.buyProduct` never reaches the
    /// app's eligibility.
    func testFreeWeekUntilTheAccountHasUsedIt() async throws {
        let monthly = try await product("com.jackwallner.mahj.monthly")
        let yearly = try await product("com.jackwallner.mahj.yearly")
        let fresh = await SubscriptionService.isTrialEligible(monthly)
        XCTAssertTrue(fresh, "a new account gets the free week")

        let result = try await yearly.purchase()
        guard case .success(.verified(let transaction)) = result else {
            return XCTFail("fixture purchase did not go through: \(result)")
        }
        XCTAssertEqual(transaction.offerType, .introductory, "the purchase used the free week")
        await transaction.finish()
        try session.expireSubscription(productIdentifier: yearly.id)

        // One free week per subscription group: the other plan is gone too.
        // Fetched again, as the app does on its next offerings load.
        let lapsedMonthly = await SubscriptionService.isTrialEligible(try await product(monthly.id))
        let lapsedYearly = await SubscriptionService.isTrialEligible(try await product(yearly.id))
        XCTAssertFalse(lapsedMonthly)
        XCTAssertFalse(lapsedYearly)
    }

    /// No product to ask about (no RevenueCat on a simulator, offerings not
    /// loaded) keeps the 1.3.2 behaviour rather than hiding the offer.
    func testUnknownProductReadsAsEligible() async {
        let eligible = await SubscriptionService.isTrialEligible(nil)
        XCTAssertTrue(eligible)
    }
}
