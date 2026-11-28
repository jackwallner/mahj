import SwiftUI
import XCTest
@testable import MahjTrainer

@MainActor
final class ScreenNavigationTests: XCTestCase {
    func testOpenQuestionKeepsItsParentRoute() {
        let navigation = ScreenNavigation()
        navigation.path = [
            NavigationScreen(view: AnyView(Text("Challenge")), route: .monthlyChallenge),
            NavigationScreen(view: AnyView(Text("Question")))
        ]
        XCTAssertEqual(navigation.activeRoute, .monthlyChallenge)
    }

    func testNewestRouteWinsOverAnOlderChallenge() {
        let navigation = ScreenNavigation()
        navigation.path = [
            NavigationScreen(view: AnyView(Text("Challenge")), route: .monthlyChallenge),
            NavigationScreen(view: AnyView(Text("Prep")), route: .gameNightPrepSession),
            NavigationScreen(view: AnyView(Text("Question")))
        ]
        XCTAssertEqual(navigation.activeRoute, .gameNightPrepSession)
    }

    func testManuallyStartedPrepCarriesItsReminderRoute() {
        let link = ScreenLink(route: .gameNightPrepSession) {
            Text("Prep")
        } label: {
            Text("Start")
        }
        let navigation = ScreenNavigation()
        navigation.path = [link.navigationScreen]
        XCTAssertEqual(navigation.activeRoute, .gameNightPrepSession)
    }

    func testSeparateOpensHaveSeparateIdentity() {
        let first = NavigationScreen(id: "practice", view: AnyView(Text("Practice")))
        let second = NavigationScreen(id: "practice", view: AnyView(Text("Practice")))
        XCTAssertEqual(first, first)
        XCTAssertNotEqual(first, second)
    }
}
