import XCTest
@testable import MahjTrainer

final class TrialOfferPacerTests: XCTestCase {
    private var defaults: UserDefaults!
    private let suite = "TrialOfferPacerTests"
    private let day: TimeInterval = 24 * 60 * 60

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suite)
        defaults.removePersistentDomain(forName: suite)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
        super.tearDown()
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Chicago")!
        return calendar
    }

    /// Install at 9am, so "day 1" is the next calendar day.
    private var installed: Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: 2, hour: 9))!
    }

    private func due(_ now: Date, practices: Int = 5) -> Bool {
        TrialOfferPacer.autoOfferDue(practicesSinceOnboarding: practices, installedAt: installed, now: now,
                                     calendar: calendar, defaults: defaults)
    }

    private func ask(_ now: Date) {
        TrialOfferPacer.markAutoShown(installedAt: installed, now: now, calendar: calendar, defaults: defaults)
    }

    func testWaitsForTheSecondPracticeAfterOnboarding() {
        TrialOfferPacer.noteForeground(now: installed, defaults: defaults)
        XCTAssertFalse(due(installed, practices: 0))
        XCTAssertFalse(due(installed, practices: 1))
        XCTAssertTrue(due(installed, practices: 2))
    }

    func testInstallDayAndNextAreOncePerSession() {
        var now = installed
        TrialOfferPacer.noteForeground(now: now, defaults: defaults)
        XCTAssertTrue(due(now))
        ask(now)
        XCTAssertFalse(due(now + 600), "one ask per session")

        // A quick trip away is the same session, even reported twice.
        TrialOfferPacer.noteBackground(now: now + 700, defaults: defaults)
        TrialOfferPacer.noteForeground(now: now + 900, defaults: defaults)
        TrialOfferPacer.noteForeground(now: now + 901, defaults: defaults)
        XCTAssertFalse(due(now + 1000))

        // Back after half an hour: a new session, a new ask.
        TrialOfferPacer.noteBackground(now: now + 1000, defaults: defaults)
        now += 1000 + TrialOfferPacer.sessionBreak
        TrialOfferPacer.noteForeground(now: now, defaults: defaults)
        TrialOfferPacer.noteForeground(now: now + 1, defaults: defaults)
        XCTAssertTrue(due(now))
        ask(now)

        // The next morning is still session paced.
        TrialOfferPacer.noteBackground(now: now + 60, defaults: defaults)
        now = calendar.date(byAdding: .hour, value: 24, to: installed)!
        TrialOfferPacer.noteForeground(now: now, defaults: defaults)
        XCTAssertTrue(TrialOfferPacer.isSessionPaced(installedAt: installed, now: now, calendar: calendar))
        XCTAssertTrue(due(now))
        ask(now)
        XCTAssertEqual(defaults.integer(forKey: TrialOfferPacer.dayPacedCountKey), 0)
    }

    func testAtMostThreeASessionPacedDay() {
        var now = installed
        TrialOfferPacer.noteForeground(now: now, defaults: defaults)
        for visit in 1...4 {
            XCTAssertEqual(due(now), visit <= TrialOfferPacer.sessionPacedDailyCap, "visit \(visit)")
            if due(now) { ask(now) }
            TrialOfferPacer.noteBackground(now: now + 60, defaults: defaults)
            now += 60 + TrialOfferPacer.sessionBreak
            TrialOfferPacer.noteForeground(now: now, defaults: defaults)
        }
        // The cap resets with the next day.
        now = calendar.date(byAdding: .day, value: 1, to: installed)!
        TrialOfferPacer.noteBackground(now: now - 1, defaults: defaults)
        TrialOfferPacer.noteForeground(now: now + TrialOfferPacer.sessionBreak, defaults: defaults)
        XCTAssertTrue(due(now + TrialOfferPacer.sessionBreak))
    }

    func testAfterTheFirstTwoDaysAsksAreDaysApart() {
        TrialOfferPacer.noteForeground(now: installed, defaults: defaults)
        var now = calendar.date(byAdding: .day, value: 1, to: installed)!
        ask(now)
        now = calendar.date(byAdding: .day, value: 2, to: installed)!
        XCTAssertFalse(TrialOfferPacer.isSessionPaced(installedAt: installed, now: now, calendar: calendar))
        // Sessions no longer matter; days since the last ask do.
        for gapDays in [3.0, 7, 14, 14] {
            let last = defaults.object(forKey: TrialOfferPacer.lastShownKey) as! Date
            XCTAssertFalse(due(last + (gapDays - 0.5) * day))
            now = last + gapDays * day
            XCTAssertTrue(due(now))
            ask(now)
        }
    }

    func testSplitDealsOneArmAndKeepsIt() {
        XCTAssertEqual(OfferPitch.benefits.arm(defaults: defaults), .benefits)
        XCTAssertEqual(OfferPitch.timeline.arm(defaults: defaults), .timeline)
        XCTAssertNil(defaults.string(forKey: OfferPitch.armKey))
        XCTAssertEqual(OfferPitch.split.arm(defaults: defaults, coin: { true }), .timeline)
        XCTAssertEqual(OfferPitch.split.arm(defaults: defaults, coin: { false }), .timeline, "kept for good")
        defaults.removeObject(forKey: OfferPitch.armKey)
        XCTAssertEqual(OfferPitch.split.arm(defaults: defaults, coin: { false }), .benefits)
        // No metadata is the control.
        XCTAssertEqual(RemoteConfig.value(OfferPitch.metadataKey, in: nil, default: OfferPitch.benefits), .benefits)
        XCTAssertEqual(RemoteConfig.value(OfferPitch.metadataKey, in: ["offer_pitch": "split"], default: OfferPitch.benefits), .split)
    }

    func testRatingPromptStandsDownRightAfterAnAutoAsk() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        XCTAssertFalse(TrialOfferPacer.autoShownRecently(now: now, defaults: defaults))
        TrialOfferPacer.markAutoShown(installedAt: nil, now: now, defaults: defaults)
        XCTAssertTrue(TrialOfferPacer.autoShownRecently(now: now + 10, defaults: defaults))
        XCTAssertFalse(TrialOfferPacer.autoShownRecently(now: now + 600, defaults: defaults))
    }

    func testOfferCopyNeverAssumesTheModeName() {
        for line in TrialOfferSheet.benefits + RemoteConfigBenefitLines.all {
            XCTAssertFalse(line.localizedCaseInsensitiveContains("Play a Hand"), line)
            XCTAssertFalse(line.contains("\u{2014}"), line)
        }
    }
}

private enum RemoteConfigBenefitLines {
    static var all: [String] { TrialBenefits.allCases.flatMap(\.lines) }
}
