import XCTest

/// Audit walk: a first-time player who knows nothing about the app taps the
/// obvious primary button on every screen. Attaches a screenshot and the list
/// of visible buttons per step so a reviewer can judge the first minutes.
@MainActor
final class NewcomerWalkTests: XCTestCase {
    func testFirstRunWalk() {
        continueAfterFailure = true
        let app = XCUIApplication()
        app.launchArguments = ["-progress.hasOnboarded", "NO", "-mahj.hasReadPrimer", "NO"]
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: 30)
        attach("launch", "launched")

        let prefer = ["I'm brand new", "Brand new", "Start free trial", "Continue", "Next", "Get Started",
                      "Skip for now", "Skip the tour", "Skip it, take me to the app", "Maybe later", "Not now"]
        for step in 0..<16 {
            sleep(2)
            attach("step\(step)", "state=\(app.state.rawValue)")
            // Never buy: skip trial/purchase buttons.
            let pick = prefer.filter { !$0.lowercased().contains("trial") }
                .compactMap { l -> XCUIElement? in
                    let b = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", l)).firstMatch
                    return b.exists && b.isHittable ? b : nil
                }.first
            guard let button = pick else { continue }
            button.tap()
        }
        sleep(2)
        attach("final", app.debugDescription)
    }

    private func attach(_ name: String, _ text: String) {
        let s = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        s.name = name; s.lifetime = .keepAlways; add(s)
        let t = XCTAttachment(string: text)
        t.name = name + "_buttons"; t.lifetime = .keepAlways; add(t)
    }
}
