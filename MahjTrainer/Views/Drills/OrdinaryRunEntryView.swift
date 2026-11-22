import SwiftUI

/// A room drill with a saved run asks Resume or Start over. Keep the decision
/// outside the runner so Start over builds fresh view state.
struct OrdinaryRunEntryView<Content: View>: View {
    let id: String
    let title: String
    let content: () -> Content
    @State private var saved: OrdinaryRun?
    @State private var decided = false

    init(id: String, title: String, @ViewBuilder content: @escaping () -> Content) {
        self.id = id
        self.title = title
        self.content = content
        _saved = State(initialValue: OrdinaryRunStore.shared.run(for: id))
    }

    var body: some View {
        entry.tracksOrdinaryRun(id)
    }

    @ViewBuilder
    private var entry: some View {
        if let saved, !decided {
            VStack(spacing: 18) {
                Spacer()
                // The bar already names the drill; the middle says what
                // Resume brings back.
                Text(Self.position(of: saved))
                    .font(Theme.display(28))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                    .monospacedDigit()
                Spacer()
                Button { decided = true } label: {
                    Text("Resume").primaryCTA()
                }
                Button("Start over") {
                    OrdinaryRunStore.shared.clear(saved.id)
                    decided = true
                }
                .foregroundStyle(Theme.inkSecondary)
            }
            .padding()
            .frame(maxWidth: Theme.readableContentWidth)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.background)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        } else {
            content()
        }
    }

    /// Where the saved run stands: cards down for a deck, otherwise the
    /// question (or deal) it resumes on.
    static func position(of run: OrdinaryRun) -> String {
        let total = run.drill.kind.itemCount
        if case .flashcards = run.drill.kind {
            return String(localized: "\(total - run.queue.count) of \(total) down")
        }
        return String(localized: "Question \(min(run.index + 1, total)) of \(total)")
    }
}

/// Home's Resume card goes straight back into the run, no second choice.
/// Home only offers a run this player may open; the check here keeps a
/// lapsed member out of a locked drill whatever the route.
struct SavedOrdinaryRunView: View {
    @EnvironmentObject private var subscriptions: SubscriptionService
    /// The latest room drill Home offers: the same pick as its Resume card.
    @State private var run = OrdinaryRunStore.shared.resumableRoomRun(
        besideOpenPane: false, isMember: SubscriptionService.shared.isPro)

    var body: some View {
        if let run, !run.isLocked(isMember: subscriptions.isPro) {
            Group {
                if run.isQuickSession {
                    QuickSessionView(items: run.items)
                } else {
                    RoomDrillView(drill: run.drill, accent: DrillLibrary.rooms.first {
                        $0.id == DrillLibrary.roomID(forDrillID: run.id)
                    }?.accent ?? Theme.jade)
                }
            }
            .tracksOrdinaryRun(run.id)
        }
    }
}

extension View {
    /// Marks the run as on screen, so Home's Resume card hides beside it on
    /// the unfolded Duo.
    func tracksOrdinaryRun(_ id: String) -> some View {
        onAppear { OrdinaryRunStore.shared.setOnScreen(id, true) }
            .onDisappear { OrdinaryRunStore.shared.setOnScreen(id, false) }
    }
}

struct RoomDrillView: View {
    let drill: Drill
    var accent: Color = Theme.jade

    var body: some View {
        switch drill.kind {
        case .flashcards(let cards): FlashcardDrillView(drill: drill, cards: cards, accent: accent)
        case .quiz(let questions): QuizDrillView(drill: drill, questions: questions)
        case .handMatch(let questions): HandMatchDrillView(drill: drill, questions: questions)
        case .charleston(let scenarios): CharlestonDrillView(drill: drill, scenarios: scenarios)
        }
    }
}
