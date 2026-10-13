import Foundation

var greg = Calendar(identifier: .gregorian)
greg.timeZone = TimeZone(secondsFromGMT: 0)!
let now = greg.date(from: DateComponents(year: 2026, month: 10, day: 12))!
for id: Calendar.Identifier in [.gregorian, .buddhist, .hebrew, .islamicUmmAlQura, .indian, .japanese] {
    var cal = Calendar(identifier: id)
    cal.timeZone = greg.timeZone
    let challenge = MonthlyChallengeContent.challenge(for: now, calendar: cal)
    let past = MonthlyChallengeContent.pastMonths(before: now, calendar: cal)
    print("CAL", id, "key", challenge.monthKey, "title", challenge.title, "theme", challenge.theme, "archiveCount", past.count)
}
var history: [MonthlyChallengeTheme: [String: String]] = [:]
for offset in 0..<39 {
    let date = greg.date(byAdding: .month, value: offset, to: now)!
    let challenge = MonthlyChallengeContent.challenge(for: date, calendar: greg)
    let closers = challenge.items.suffix(3)
    print("MONTH", challenge.monthKey, challenge.theme, "count", challenge.items.count, "closers", closers.map(\.id).joined(separator: ","), "section", closers.filter { $0.roomID == "card-room" }.map { $0.choices[$0.answerIndex] })
    for item in closers {
        let identity = item.id.hasPrefix("monthly-charleston-") ? item.id.split(separator: "-").last.map(String.init)! : item.id
        if let prior = history[challenge.theme]?[identity] { print("REPEAT", challenge.monthKey, identity, "previous", prior) }
        history[challenge.theme, default: [:]][identity] = challenge.monthKey
    }
}
let december = MonthlyChallengeContent.challenge(monthKey: "2026-12", calendar: greg)!
for (i, item) in december.items.enumerated() { print("DECEMBER", i+1, item.id, item.prompt, "ANSWER", item.choices[item.answerIndex], "EXPLANATION", item.explanation) }
for n in 0..<3000 {
    let deal = HandPlayEngine.deal(seed: "run-audit-\(n)")
    let rack = deal.rack + [deal.wall[0]]
    let range = HandPlayEngine.bestRunRange(for: rack)
    let off = Set(rack.filter { !HandPlayEngine.belongs($0, to: .consecutiveRun, runRange: range) })
    let best = HandPlayEngine.bestDiscards(from: rack, target: .consecutiveRun)
    if !off.isEmpty && !off.isSubset(of: best) {
        print("RUNCOUNTEREXAMPLE", n, rack.map(\.shortLabel), "range", range, "off", off.map(\.shortLabel), "best", best.map(\.shortLabel))
        for tile in Set(rack).sorted(by: { $0.sortKey < $1.sortKey }) {
            var rem = rack; rem.remove(at: rem.firstIndex(of: tile)!)
            print("DISCARD", tile.shortLabel, "value", HandPlayEngine.value(of: rem,target: .consecutiveRun), "range", HandPlayEngine.bestRunRange(for: rem), "note", HandPlayEngine.coachNote(for: tile, rack:rack,target: .consecutiveRun,wasBest:best.contains(tile)))
        }
        break
    }
}
