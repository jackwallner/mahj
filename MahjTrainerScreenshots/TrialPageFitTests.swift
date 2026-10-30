import UIKit
import XCTest

/// The onboarding trial page's benefit rows must read in full in every
/// shipped language. On an iPhone SE the 1.3.2 page had no room for the
/// longer 1.4.1 rows and the translations, and SwiftUI cut them to one line
/// with an ellipsis. Run it on the smallest supported iPhone:
/// `gh-sim test --scheme Screenshots --device "iPhone SE (3rd generation)"
/// --only MahjTrainerScreenshots/TrialPageFitTests`.
///
/// A row is cut off when its drawn frame is shorter than the text needs at
/// that width. Every language and both benefit arms attach a screenshot.
@MainActor
final class TrialPageFitTests: XCTestCase {
    private let languages = ["en", "de", "es", "fr", "id", "vi"]
    private let arms = ["reassure_first", "paid_first"]

    override func setUp() {
        continueAfterFailure = true
        XCUIDevice.shared.orientation = .portrait
    }

    func testEveryBenefitRowReadsInFull() {
        let app = XCUIApplication()
        for language in languages {
            for arm in arms {
                app.terminate()
                app.launchArguments = [
                    "-AppleLanguages", "(\(language))",
                    "-AppleLocale", language,
                    "-progress.hasOnboarded", "NO",
                    "-subscription.localProOverride", "NO",
                    "-reviewPrompt.launchCount", "0",
                    "-mahj.onboardingPage", "4",
                    "-mahj.rc.trial_benefits", arm,
                ]
                app.launch()
                let rows = app.staticTexts.matching(identifier: "trialBenefit")
                XCTAssertTrue(rows.firstMatch.waitForExistence(timeout: 20), "\(language) \(arm): no benefit rows")
                Thread.sleep(forTimeInterval: 1.5)
                attachScreenshot("trial_\(language)_\(arm)")
                let screen = app.windows.firstMatch.frame
                XCTAssertGreaterThanOrEqual(rows.count, 4, "\(language) \(arm)")
                for index in 0..<rows.count {
                    let row = rows.element(boundBy: index)
                    let label = row.label
                    // Only the scrolling fallback may put a row below the fold.
                    if !screen.contains(row.frame) { continue }
                    let needed = Self.height(of: label, width: row.frame.width)
                    XCTAssertLessThanOrEqual(
                        needed, row.frame.height + 4,
                        "\(language) \(arm): \"\(label)\" is cut off (\(row.frame.height)pt drawn, \(needed)pt needed)"
                    )
                }
            }
        }
    }

    /// The height the row's text needs at the width it was given, in the
    /// row's `.subheadline` font at the default text size. Two points of
    /// slack on the width so a line SwiftUI fitted exactly never wraps here.
    private static func height(of text: String, width: CGFloat) -> CGFloat {
        let font = UIFont.preferredFont(forTextStyle: .subheadline, compatibleWith: UITraitCollection(preferredContentSizeCategory: .large))
        let rect = (text as NSString).boundingRect(
            with: CGSize(width: width + 2, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        return ceil(rect.height)
    }

    private func attachScreenshot(_ name: String) {
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "shot_\(name)"
        shot.lifetime = .keepAlways
        add(shot)
    }
}
