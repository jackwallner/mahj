import XCTest
@testable import MahjTrainer

/// B11: the streak and install-day pacing across a clock change that skips local midnight.
extension LowBugRegressionTests {
    // MARK: B11 streak across a clock change that skips local midnight

    /// Lebanon moves 00:00 to 01:00 on 2027-03-28, so that day starts at 01:00.
    func testStreakCountsEveryDayAcrossALebanonClockChange() {
        inTimeZone("Asia/Beirut") { calendar in
            let saturday = calendar.date(from: DateComponents(year: 2027, month: 3, day: 27, hour: 20))!
            let sunday = calendar.date(from: DateComponents(year: 2027, month: 3, day: 28, hour: 20))!
            let monday = calendar.date(from: DateComponents(year: 2027, month: 3, day: 29, hour: 20))!
            XCTAssertEqual(calendar.component(.hour, from: calendar.startOfDay(for: sunday)), 1,
                           "the change day starts at 01:00 in this zone")
            let store = ProgressStore(defaults: freshDefaults("LowBugStreakBeirut"))
            store.recordSession(drillID: "a", now: saturday)
            store.recordSession(drillID: "a", now: sunday)
            store.recordSession(drillID: "a", now: monday)
            XCTAssertEqual(store.streakCount, 3)
            XCTAssertEqual(store.currentStreak(now: monday), 3)
        }
    }

    func testASkippedDayAfterALebanonClockChangeStillBreaksTheStreak() {
        inTimeZone("Asia/Beirut") { calendar in
            let saturday = calendar.date(from: DateComponents(year: 2027, month: 3, day: 27, hour: 20))!
            let sunday = calendar.date(from: DateComponents(year: 2027, month: 3, day: 28, hour: 20))!
            let tuesday = calendar.date(from: DateComponents(year: 2027, month: 3, day: 30, hour: 20))!
            let store = ProgressStore(defaults: freshDefaults("LowBugStreakBeirutSkip"))
            store.recordSession(drillID: "a", now: saturday)
            store.recordSession(drillID: "a", now: sunday)
            XCTAssertEqual(store.currentStreak(now: tuesday), 0)
            store.recordSession(drillID: "a", now: tuesday)
            XCTAssertEqual(store.streakCount, 1)
        }
    }

    func testInstallDayPacingAcrossALebanonClockChange() {
        inTimeZone("Asia/Beirut") { calendar in
            let installed = calendar.date(from: DateComponents(year: 2027, month: 3, day: 28, hour: 20))!
            let monday = calendar.date(from: DateComponents(year: 2027, month: 3, day: 29, hour: 12))!
            let tuesday = calendar.date(from: DateComponents(year: 2027, month: 3, day: 30, hour: 12))!
            XCTAssertTrue(TrialOfferPacer.isSessionPaced(installedAt: installed, now: monday, calendar: calendar))
            XCTAssertFalse(TrialOfferPacer.isSessionPaced(installedAt: installed, now: tuesday, calendar: calendar),
                           "two calendar days after install is day paced")
        }
    }
}
