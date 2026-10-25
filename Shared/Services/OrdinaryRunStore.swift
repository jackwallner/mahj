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
}

@MainActor
final class OrdinaryRunStore: ObservableObject {
    static let shared = OrdinaryRunStore()
    static let key = "practice.ordinaryRun"

    @Published private(set) var inProgress: OrdinaryRun?
    /// The run a runner has on screen. The unfolded Duo keeps Home beside an
    /// open drill, and its Resume card must not offer the drill in view.
    @Published private(set) var onScreenID: String?
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.key) {
            inProgress = try? JSONDecoder().decode(OrdinaryRun.self, from: data)
        }
    }

    func run(for id: String) -> OrdinaryRun? {
        inProgress?.id == id ? inProgress : nil
    }

    func save(_ run: OrdinaryRun) {
        guard run.drill.kind.itemCount > 0 || !run.items.isEmpty else { return }
        guard let data = try? JSONEncoder().encode(run) else { return }
        defaults.set(data, forKey: Self.key)
        inProgress = run
    }

    func setOnScreen(_ id: String, _ isOnScreen: Bool) {
        if isOnScreen {
            onScreenID = id
        } else if onScreenID == id {
            onScreenID = nil
        }
    }

    /// Home's Resume card, unless that run is already open beside Home.
    func resumable(besideOpenPane: Bool) -> OrdinaryRun? {
        guard let inProgress, !(besideOpenPane && onScreenID == inProgress.id) else { return nil }
        return inProgress
    }

    func clear(_ id: String) {
        guard inProgress?.id == id else { return }
        defaults.removeObject(forKey: Self.key)
        inProgress = nil
    }
}
