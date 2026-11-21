import Foundation

/// One ordinary run, saved at answer and advance boundaries like Play a Hand.
struct OrdinaryRun: Codable, Sendable {
    var drill: Drill
    var items: [QuickItem] = []
    var index = 0
    var score = 0
    var selection: Int?
    var answers: [Bool] = []
    var selected: Set<Int> = []
    var submitted = false
    var queue: [Flashcard] = []
    var flipped = false
    var pendingAnswer: AnswerSnapshot?
    var lastSwipe: SwipeRecord?

    struct AnswerSnapshot: Codable, Sendable {
        let progress: ProgressStore.ItemSnapshot
        let practice: PracticeRecordStore.AnswerSnapshot
    }

    struct SwipeRecord: Codable, Sendable {
        let card: Flashcard
        let gotIt: Bool
        let answer: AnswerSnapshot
    }

    var id: String { drill.id }
    var isQuickSession: Bool { id == SessionBuilder.sessionDrill.id }
    /// Only a run with an answer is worth resuming. Opening a drill and
    /// leaving it is not progress.
    var hasAnswers: Bool { !answers.isEmpty }

    /// A lapsed member keeps the run on disk but never replays it: a room
    /// drill locks through `Room.isLocked`, a Quick Session on the Mahj+
    /// questions it was built with.
    func isLocked(isMember: Bool) -> Bool {
        guard !isMember else { return false }
        if isQuickSession { return items.contains { SessionBuilder.isMemberOnly($0.id) } }
        guard let room = DrillLibrary.room(id: DrillLibrary.roomID(forDrillID: id)) else { return false }
        return room.isLocked(drill, isMember: isMember)
    }
}

@MainActor
final class OrdinaryRunStore: ObservableObject {
    static let shared = OrdinaryRunStore()
    /// The single-slot key of 1.4.x. Still read once, so an install that
    /// saved a run before the update keeps it.
    static let key = "practice.ordinaryRun"
    /// One saved run per drill, oldest first.
    static let runsKey = "practice.ordinaryRuns"

    /// Every run with answers, one per drill id, the most recently answered last.
    @Published private(set) var runs: [OrdinaryRun] = []
    /// The run a runner has on screen. The unfolded Duo keeps Home beside an
    /// open drill, and its Resume card must not offer the drill in view.
    @Published private(set) var onScreenID: String?
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.runsKey),
           let saved = try? JSONDecoder().decode([OrdinaryRun].self, from: data) {
            runs = saved.filter(\.hasAnswers)
        } else if let data = defaults.data(forKey: Self.key),
                  let run = try? JSONDecoder().decode(OrdinaryRun.self, from: data), run.hasAnswers {
            runs = [run]
        }
    }

    /// The most recently answered run.
    var inProgress: OrdinaryRun? { runs.last }

    func run(for id: String) -> OrdinaryRun? {
        runs.first { $0.id == id }
    }

    /// Each drill keeps its own run, so answering in one never drops the
    /// place in another (a Tile Check answer wiped a half-done Quick
    /// Session). An unanswered run never takes a slot, and the same run
    /// undone back to nothing drops out.
    func save(_ run: OrdinaryRun) {
        guard run.drill.kind.itemCount > 0 || !run.items.isEmpty else { return }
        guard run.hasAnswers else { return clear(run.id) }
        var updated = runs.filter { $0.id != run.id }
        updated.append(run)
        persist(updated)
    }

    func setOnScreen(_ id: String, _ isOnScreen: Bool) {
        if isOnScreen {
            onScreenID = id
        } else if onScreenID == id {
            onScreenID = nil
        }
    }

    /// Home's Resume cards, most recent first, leaving out a run already
    /// open beside Home or locked to this player.
    func resumable(besideOpenPane: Bool, isMember: Bool) -> [OrdinaryRun] {
        runs.reversed().filter {
            $0.hasAnswers && !$0.isLocked(isMember: isMember) && !(besideOpenPane && onScreenID == $0.id)
        }
    }

    /// The run behind Home's Resume card: the latest room drill. A saved
    /// Quick Session resumes from the Get Started card instead.
    func resumableRoomRun(besideOpenPane: Bool, isMember: Bool) -> OrdinaryRun? {
        resumable(besideOpenPane: besideOpenPane, isMember: isMember).first { !$0.isQuickSession }
    }

    func hasResumableQuickSession(besideOpenPane: Bool, isMember: Bool) -> Bool {
        resumable(besideOpenPane: besideOpenPane, isMember: isMember).contains { $0.isQuickSession }
    }

    func clear(_ id: String) {
        guard runs.contains(where: { $0.id == id }) else { return }
        persist(runs.filter { $0.id != id })
    }

    func clearAll() {
        persist([])
    }

    private func persist(_ updated: [OrdinaryRun]) {
        if updated.isEmpty {
            defaults.removeObject(forKey: Self.runsKey)
        } else if let data = try? JSONEncoder().encode(updated) {
            defaults.set(data, forKey: Self.runsKey)
        } else {
            return
        }
        defaults.removeObject(forKey: Self.key)
        runs = updated
    }
}
