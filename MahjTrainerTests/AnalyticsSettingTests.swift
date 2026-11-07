import XCTest
@testable import MahjTrainer

@MainActor
final class AnalyticsSettingTests: XCTestCase {
    private var defaults: UserDefaults!
    private let suite = "AnalyticsSettingTests"

    override func setUp() async throws {
        defaults = UserDefaults(suiteName: suite)
        defaults.removePersistentDomain(forName: suite)
    }

    override func tearDown() async throws {
        defaults.removePersistentDomain(forName: suite)
    }

    func testSharingDefaultsOnAndTheChoiceSurvivesRelaunch() {
        let settings = AppSettings(defaults: defaults)
        XCTAssertTrue(settings.shareUsageData)
        settings.shareUsageData = false
        XCTAssertFalse(AppSettings(defaults: defaults).shareUsageData)
    }
}
