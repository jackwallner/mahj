import SwiftUI

struct RoomView: View {
    let room: Room
    @EnvironmentObject private var progress: ProgressStore

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(room.drills) { drill in
                    NavigationLink {
                        drillDestination(drill)
                    } label: {
                        drillCard(drill)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle(room.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func drillDestination(_ drill: Drill) -> some View {
        switch drill.kind {
        case .flashcards(let cards):
            FlashcardDrillView(drill: drill, cards: cards)
        case .quiz(let questions):
            QuizDrillView(drill: drill, questions: questions)
        case .handMatch(let questions):
            HandMatchDrillView(drill: drill, questions: questions)
        case .charleston(let scenarios):
            CharlestonDrillView(drill: drill, scenarios: scenarios)
        }
    }

    private func drillCard(_ drill: Drill) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(drill.title)
                    .font(.headline)
                Text(drill.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("\(drill.kind.itemCount) cards · completed \(progress.completions(for: drill.id))×")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            Spacer(minLength: 4)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 18))
    }
}
