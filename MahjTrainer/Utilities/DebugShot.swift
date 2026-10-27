#if DEBUG
import SwiftUI

/// Screenshot routes for the iPhone Duo capture, DEBUG builds only.
/// `mahj://shot/<name>` opens one screen from anywhere:
/// home, settings, paywall, reference, stats, challenge, quick, handplay,
/// room/<room-id>, drill/<drill-id>. gh-sim passes the links with `--url`.
/// Unfolded, Home stays in the leading pane and the screen opens beside it.
@MainActor
enum DebugShot {
    static func pushes(_ name: String) -> Bool {
        !["home", "settings", "paywall"].contains(name)
    }

    /// The room a `room/` or `drill/` route belongs to.
    static func roomID(_ name: String) -> String? {
        let parts = name.split(separator: "/").map(String.init)
        guard parts.count == 2 else { return nil }
        switch parts[0] {
        case "room": return parts[1]
        case "drill": return DrillLibrary.roomID(forDrillID: parts[1])
        default: return nil
        }
    }

    @ViewBuilder
    static func screen(_ name: String) -> some View {
        let parts = name.split(separator: "/").map(String.init)
        switch (parts.first, parts.last) {
        case ("reference", _): ReferenceView()
        case ("stats", _): StatsView()
        case ("challenge", _): MonthlyChallengeView()
        case ("handplay", _): HandPlayView()
        case ("quick", _):
            QuickSessionView(items: SessionBuilder.quickSession(seen: [], missed: [], includePro: true))
                .tracksOrdinaryRun(SessionBuilder.sessionDrill.id)
        case ("room", let id?):
            if let room = DrillLibrary.room(id: id) { RoomView(room: room) }
        case ("drill", let id?):
            if let room = DrillLibrary.room(id: DrillLibrary.roomID(forDrillID: id)),
               let drill = room.drills.first(where: { $0.id == id }) {
                RoomView(room: room).drillScreen(drill)
            }
        default: EmptyView()
        }
    }

    /// `-mahj.shot <name>` opens the same screen at launch, for runs where
    /// `simctl openurl` stops on iOS's "Open in" prompt. Held a beat so Home
    /// has measured the fold and the screen lands in the trailing pane.
    static func routeIfRequested(_ router: AppRouter) {
        // Each capture launch starts with no run in progress: gh-sim keeps
        // the install between screens, and the last screen's drill showed
        // up as Home's Resume card on the next.
        if ProcessInfo.processInfo.arguments.contains("-mahj.demoSeed"),
           let run = OrdinaryRunStore.shared.inProgress {
            OrdinaryRunStore.shared.clear(run.id)
        }
        guard let name = UserDefaults.standard.string(forKey: "mahj.shot") else { return }
        Task {
            try? await Task.sleep(for: .seconds(2))
            router.route(to: .debugShot(name))
        }
    }

    /// `-mahj.demoSeed YES` gives a fresh install a week of real practice,
    /// recorded through the same stores a player's answers go through, so
    /// the captures show a returning player rather than empty rings. Once
    /// per install: gh-sim relaunches the app when it unfolds the Duo.
    static func seedIfRequested() {
        let defaults = UserDefaults.standard
        guard ProcessInfo.processInfo.arguments.contains("-mahj.demoSeed"),
              !defaults.bool(forKey: "debug.demoSeeded") else { return }
        defaults.set(true, forKey: "debug.demoSeeded")
        let progress = ProgressStore.shared
        let records = PracticeRecordStore.shared
        let now = Date()
        // Share of each room's questions answered right twice, in room order.
        let shares = [0.9, 0.6, 0.45, 0.3, 0.2]
        for (index, room) in DrillLibrary.rooms.enumerated() {
            let ids = PracticeRecordStore.trackableItemIDs(in: room, isMember: true)
            let known = Int(Double(ids.count) * shares[min(index, shares.count - 1)])
            for id in ids.prefix(known) {
                records.record(itemID: id, roomID: room.id, correct: true, now: now.addingTimeInterval(-86_400))
                records.record(itemID: id, roomID: room.id, correct: true, now: now)
                progress.recordItem(id: id, correct: true)
            }
        }
        // Eight days running, two or three drills a day.
        let drills = DrillLibrary.rooms.flatMap(\.drills).map(\.id)
        for day in (0..<8).reversed() {
            let date = Calendar.current.date(byAdding: .day, value: -day, to: now) ?? now
            for slot in 0..<(2 + day % 2) {
                progress.recordSession(drillID: drills[(day * 3 + slot) % drills.count], now: date)
            }
        }
    }
}
#endif
