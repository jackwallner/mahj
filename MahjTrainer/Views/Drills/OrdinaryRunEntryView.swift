import SwiftUI

/// Keep the decision outside the runner so Start over builds fresh view state.
struct OrdinaryRunEntryView<Content: View>: View {
    let title: String
    let content: () -> Content
    @State private var saved: OrdinaryRun?
    @State private var decided = false

    init(id: String, title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
        _saved = State(initialValue: OrdinaryRunStore.shared.run(for: id))
    }

    var body: some View {
        if let saved, !decided {
            VStack(spacing: 18) {
                Spacer()
                Text(title).font(Theme.display(28)).foregroundStyle(Theme.ink)
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
}

struct SavedOrdinaryRunView: View {
    @State private var run = OrdinaryRunStore.shared.inProgress

    var body: some View {
        if let run {
            OrdinaryRunEntryView(id: run.id, title: run.drill.title) {
                if run.isQuickSession {
                    QuickSessionView(items: run.items)
                } else {
                    RoomDrillView(drill: run.drill, accent: DrillLibrary.rooms.first {
                        $0.id == DrillLibrary.roomID(forDrillID: run.id)
                    }?.accent ?? Theme.jade)
                }
            }
        }
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
