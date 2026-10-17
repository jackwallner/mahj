import RevenueCat
import XCTest
@testable import MahjTrainer

/// Proves the trial-button experiment end to end through the real RevenueCat
/// SDK: the offering metadata RevenueCat serves is what `TrialCTA` and the
/// remote switches read. Unit tests feed `TrialCTA.from` hand-built
/// dictionaries; this one feeds it what the network actually returns.
///
/// Uses the Test Store key only (a separate RevenueCat app in the same
/// project, never the production `appl_` key), so it creates no App Store
/// customer and touches no chart. Network, so opt-in:
/// `TEST_RUNNER_RC_LIVE=1 xcodebuild test ... -only-testing:MahjTrainerTests/LiveOfferingMetadataTests`
final class LiveOfferingMetadataTests: XCTestCase {
    override func setUpWithError() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["RC_LIVE"] == "1", "Set TEST_RUNNER_RC_LIVE=1 to run")
    }

    @MainActor
    func testExperimentOfferingsCarryTheButtonWording() async throws {
        if !Purchases.isConfigured {
            Purchases.configure(
                with: Configuration.Builder(withAPIKey: RevenueCatProbe.testStoreKey)
                    .with(appUserID: "metadata-probe-mahj")
                    .build()
            )
        }
        let offerings = try await Purchases.shared.offerings()

        // Control: the default offering, which every 1.3.2 player and every
        // non-enrolled 1.4.1 player gets. No metadata means 1.3.2's button.
        let control = try XCTUnwrap(offerings.all["default"])
        XCTAssertEqual(TrialCTA.from(metadata: control.metadata), .sevenDay)
        XCTAssertEqual(TrialCTA.sevenDay.title(.onboarding), "Start 7-day free trial")
        XCTAssertTrue(RemoteConfig.isOn(.attPrompt, in: control.metadata))
        XCTAssertTrue(RemoteConfig.isOn(.ratingPrompt, in: control.metadata))

        // Treatment: cta_my, the only difference is the button.
        let treatment = try XCTUnwrap(offerings.all["cta_my"])
        XCTAssertEqual(TrialCTA.from(metadata: treatment.metadata), .my)
        XCTAssertEqual(TrialCTA.my.title(.onboarding), "Start my free trial")
        XCTAssertEqual(
            RemoteConfig.isOn(.attPrompt, in: treatment.metadata),
            RemoteConfig.isOn(.attPrompt, in: control.metadata),
            "A switch must be the same on both arms or the experiment flips it"
        )
        XCTAssertEqual(
            RemoteConfig.value(OnboardingPlan.metadataKey, in: treatment.metadata, default: OnboardingPlan.monthly),
            .monthly
        )
    }
}
