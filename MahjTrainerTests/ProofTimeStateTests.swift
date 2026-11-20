import XCTest
@testable import MahjTrainer

/// Proof pass 2: day math in zones whose daylight saving change skips local midnight.
@MainActor
final class ProofTimeStateTests: XCTestCase {
    private var savedZone: TimeZone!
    override func setUp() { super.setUp(); savedZone = NSTimeZone.default }
    override func tearDown() { NSTimeZone.default = savedZone; super.tearDown() }

    private func streakRun(_ id: String, from start: DateComponents, days: Int) throws -> [Int] {
        let tz = try XCTUnwrap(TimeZone(identifier: id))
        NSTimeZone.default = tz
        try XCTSkipUnless(Calendar.current.timeZone.identifier == id, "Calendar.current ignores NSTimeZone.default")
        var cal = Calendar(identifier: .gregorian); cal.timeZone = tz
        let d = UserDefaults(suiteName: "proof2.\(id)")!
        d.removePersistentDomain(forName: "proof2.\(id)")
        let store = ProgressStore(defaults: d)
        var day = try XCTUnwrap(cal.date(from: start))
        var missed: [Int] = []
        for n in 1...days {
            store.recordSession(drillID: "meet-tiles", now: day)
            if store.streakCount != n { missed.append(n); break }
            day = cal.date(byAdding: .day, value: 1, to: day)!
        }
        return missed
    }

    private func check(_ id: String, _ start: DateComponents, _ days: Int) throws {
        let missed = try streakRun(id, from: start, days: days)
        XCTAssertTrue(missed.isEmpty, "\(id): streak failed to grow on day \(missed)")
    }

    // Start 3 days before each zone's spring change that skips local midnight.
    func testStreakCairo() throws { try check("Africa/Cairo", .init(year: 2027, month: 4, day: 27, hour: 23, minute: 30), 8) }
    func testStreakSantiago() throws { try check("America/Santiago", .init(year: 2026, month: 9, day: 2, hour: 23, minute: 30), 8) }
    func testStreakAzores() throws { try check("Atlantic/Azores", .init(year: 2027, month: 3, day: 25, hour: 23, minute: 30), 8) }
    func testStreakHavana() throws { try check("America/Havana", .init(year: 2027, month: 3, day: 11, hour: 23, minute: 30), 8) }
    func testStreakBeirut() throws { try check("Asia/Beirut", .init(year: 2027, month: 3, day: 25, hour: 23, minute: 30), 8) }
    func testStreakNewYorkControl() throws { try check("America/New_York", .init(year: 2027, month: 3, day: 11, hour: 23, minute: 30), 8) }

    /// Morning practice instead of late night: the gap-day start of day is 01:00.
    func testStreakBeirutMorningPractice() throws { try check("Asia/Beirut", .init(year: 2027, month: 3, day: 25, hour: 9, minute: 0), 8) }

    /// Fall-back day control in the same zone (25 hour day).
    func testStreakBeirutFallBack() throws { try check("Asia/Beirut", .init(year: 2026, month: 10, day: 22, hour: 23, minute: 30), 8) }

    /// Install day pacing uses the same day math.
    func testInstallDayPacingBeirut() throws {
        let tz = try XCTUnwrap(TimeZone(identifier: "Asia/Beirut"))
        var cal = Calendar(identifier: .gregorian); cal.timeZone = tz
        let installed = cal.date(from: .init(year: 2027, month: 3, day: 28, hour: 23, minute: 30))!
        let nextDay = cal.date(from: .init(year: 2027, month: 3, day: 29, hour: 23, minute: 30))!
        let twoDays = cal.date(from: .init(year: 2027, month: 3, day: 30, hour: 23, minute: 30))!
        // Day 2 after install (Mar 30) must already be past the session-paced days (0 and 1).
        XCTAssertFalse(TrialOfferPacer.isSessionPaced(installedAt: installed, now: twoDays, calendar: cal), "Mar 30 is install day + 2")
        XCTAssertTrue(TrialOfferPacer.isSessionPaced(installedAt: installed, now: nextDay, calendar: cal))
    }

    /// Challenge day math with explicit calendars (run 1 let the app read a stale zone).
    func testChallengeDayMathExplicitZones() throws {
        for id in ["America/New_York", "America/Havana", "Asia/Beirut", "Australia/Lord_Howe", "Pacific/Kiritimati",
                   "Pacific/Apia", "Africa/Cairo", "America/Santiago", "Atlantic/Azores", "Pacific/Pago_Pago"] {
            let tz = try XCTUnwrap(TimeZone(identifier: id))
            var cal = Calendar(identifier: .gregorian); cal.timeZone = tz
            var day = cal.date(from: .init(year: 2026, month: 10, day: 1, hour: 0, minute: 30))!
            let end = cal.date(from: .init(year: 2028, month: 12, day: 31))!
            while day < end {
                let p = cal.dateComponents([.year, .month, .day], from: day)
                let month = MonthlyChallengeContent.challenge(for: day, calendar: cal)
                let range = cal.range(of: .day, in: .month, for: day)!.count
                XCTAssertEqual(month.dayCount, range, "\(id) \(p)")
                XCTAssertEqual(month.day(of: day), p.day, "\(id) \(p)")
                XCTAssertEqual(DayClock.key(for: day, calendar: cal),
                               MonthlyChallengeContent.roundKey(monthKey: month.monthKey, day: p.day!), "\(id)")
                XCTAssertEqual(MonthlyChallengeContent.currentRound(now: day, calendar: cal)?.day, p.day, "\(id) \(p)")
                day = cal.date(byAdding: .day, value: 1, to: day)!
            }
        }
    }
}
