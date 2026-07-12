import SwiftUI

struct RoomView: View {
    let room: Room
    @EnvironmentObject private var progress: ProgressStore

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                header
                ForEach(room.drills) { drill in
                    NavigationLink {
                        drillDestination(drill)
                    } label: {
                        drillCard(drill)
                    }
                    .buttonStyle(PressableCardStyle())
                }
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle(room.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(spacing: 6) {
            Image(systemName: room.icon)
                .font(.title2.weight(.semibold))
                .foregroundStyle(room.accent)
                .frame(width: 52, height: 52)
                .background(room.accent.opacity(0.14), in: Circle())
            Text(room.tagline)
                .font(.subheadline)
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 6)
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
        let done = progress.completions(for: drill.id) > 0
        return HStack(spacing: 14) {
            Image(systemName: drill.kind.symbol)
                .font(.body.weight(.semibold))
                .foregroundStyle(room.accent)
                .frame(width: 42, height: 42)
                .background(room.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(drill.title)
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                Text(drill.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSecondary)
                    .lineLimit(2)
                Text("\(drill.kind.itemCount) \(drill.kind.unitName)")
                    .font(.caption)
                    .foregroundStyle(Theme.inkTertiary)
            }
            Spacer(minLength: 4)
            if done {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(room.accent)
            } else {
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.inkTertiary)
            }
        }
        .padding(16)
        .themedCard()
        .contentShape(RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous))
    }
}

extension DrillKind {
    var symbol: String {
        switch self {
        case .flashcards: return "rectangle.stack.fill"
        case .quiz: return "questionmark.circle.fill"
        case .handMatch: return "square.grid.3x3.fill"
        case .charleston: return "arrow.left.arrow.right"
        }
    }

    var unitName: String {
        switch self {
        case .flashcards: return "cards"
        case .quiz: return "questions"
        case .handMatch: return "racks"
        case .charleston: return "deals"
        }
    }
}
