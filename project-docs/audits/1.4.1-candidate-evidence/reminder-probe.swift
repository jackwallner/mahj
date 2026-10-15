import Foundation

enum AppNotification { static let routeKey = "mahj.route"; static let gameNightPrepValue = "game-night-prep" }

enum Membership { static let name = "Mahj+" }

@main
struct ReminderProbe {
    @MainActor static func main() {
        let calendar = Calendar.current
        let start = calendar.date(from: DateComponents(year: 2026, month: 10, day: 15, hour: 12))!
        let daily = AppSettings.dailyReminderPlan(time: DateComponents(hour: 9, minute: 0, second: 0), weeklyGain: 14, recordedAt: start, now: start)
        let weekly = AppSettings.gameNightReminderPlan(time: DateComponents(hour: 17, minute: 0, second: 0, weekday: 5), weeklyGain: 14, recordedAt: start, now: start)
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = calendar.timeZone
        for (name, plan) in [("daily", daily), ("weekly", weekly)] {
            print("\(name): count=\(plan.count) first=\(formatter.string(from: plan.first!.date)) last=\(formatter.string(from: plan.last!.date))")
            print("\(name): pending after 43 days=\(plan.filter { $0.date > start.addingTimeInterval(43 * 86400) }.count)")
        }
        let localHours = Set(daily.map { calendar.component(.hour, from: $0.date) })
        precondition(localHours == [9], "daily reminders drifted across DST")
        precondition(daily.dropFirst(2).allSatisfy { !$0.body.contains("locked in") }, "stale weekly count")
        print("PASS: chosen local hour survives DST; stale counts fall back to generic copy")
    }
}
