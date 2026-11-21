import Foundation

extension Calendar {
    /// Gregorian in the device's time zone.
    ///
    /// Shared identities (the month's challenge, the day's Mahj Minute) and
    /// stored day keys use it instead of `.current`, so a Buddhist, Hebrew or
    /// Japanese system calendar cannot hand a player different questions from
    /// everyone else, orphan their saved results, or stretch the challenge
    /// archive back thousands of "months". Months and days still turn over at
    /// local midnight.
    static var gregorianLocal: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }
}

extension Calendar {
    /// Calendar days from `start`'s day to `end`'s day, by year, month and day
    /// alone. The gap between two `startOfDay` values is wrong where a clock
    /// change skips local midnight (Lebanon, Egypt, Chile, the Azores): the
    /// day's start is then 01:00, and 01:00 to the next 00:00 is 23 hours,
    /// which reads as no days at all. Noon always exists.
    func calendarDays(from start: Date, to end: Date) -> Int {
        func noon(_ date: Date) -> Date {
            var parts = dateComponents([.year, .month, .day], from: date)
            parts.hour = 12
            return self.date(from: parts) ?? date
        }
        return dateComponents([.day], from: noon(start), to: noon(end)).day ?? 0
    }
}
