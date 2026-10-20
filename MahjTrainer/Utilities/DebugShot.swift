#if DEBUG
import SwiftUI

/// Screenshot routes for the iPhone Duo capture, DEBUG builds only.
/// `mahj://shot/<name>` opens one screen from anywhere:
/// home, settings, paywall, reference, stats, quick, room/<room-id>,
/// drill/<drill-id>. gh-sim passes the links with `--url`.
@MainActor
enum DebugShot {
    static func pushes(_ name: String) -> Bool {
        !["home", "settings", "paywall"].contains(name)
    }

    @ViewBuilder
    static func screen(_ name: String) -> some View {
        let parts = name.split(separator: "/").map(String.init)
        switch (parts.first, parts.last) {
        case ("reference", _): ReferenceView()
        case ("stats", _): StatsView()
        case ("challenge", _): MonthlyChallengeView()
        case ("quick", _): QuickSessionView(items: SessionBuilder.quickSession(seen: [], missed: [], includePro: true))
        case ("room", let id?):
            if let room = DrillLibrary.room(id: id) { RoomView(room: room) }
        case ("drill", let id?):
            if let room = DrillLibrary.room(id: DrillLibrary.roomID(forDrillID: id)),
               let drill = room.drills.first(where: { $0.id == id }) {
                RoomView(room: room).destination(drill)
            }
        default: EmptyView()
        }
    }
}
#endif
