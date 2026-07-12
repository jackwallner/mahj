import SwiftUI

struct HandMatchDrillView: View {
    let drill: Drill
    let questions: [HandMatchQuestion]

    @State private var index = 0
    @State private var selection: HandCategory?
    @State private var score = 0
    @State private var finished = false

    var body: some View {
        if finished {
            DrillCompleteView(drill: drill, score: score, total: questions.count)
        } else {
            drillBody
        }
    }

    private var question: HandMatchQuestion { questions[index] }
    private var answered: Bool { selection != nil }

    private var drillBody: some View {
        VStack(spacing: 16) {
            ProgressView(value: Double(index), total: Double(questions.count))
                .tint(Theme.felt)
            ScrollView {
                VStack(spacing: 18) {
                    Text("Which section is this rack chasing?")
                        .font(Theme.display(22))
                        .foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                    TileRackView(tiles: question.tiles.racked, tileWidth: 44)
                        .padding(.vertical, 6)
                    choiceButtons
                    if answered {
                        explanationCard
                    }
                }
            }
            footer
        }
        .padding()
        .background(Theme.background)
        .navigationTitle(drill.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var choiceButtons: some View {
        VStack(spacing: 10) {
            ForEach(question.choices) { category in
                Button {
                    select(category)
                } label: {
                    HStack {
                        Text(category.displayName)
                            .font(.body.weight(.medium))
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        if answered {
                            resultIcon(for: category)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(choiceBackground(category), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(choiceBorder(category), lineWidth: 1)
                    )
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: answered)
                }
                .buttonStyle(.plain)
                .disabled(answered)
            }
        }
    }

    @ViewBuilder
    private func resultIcon(for category: HandCategory) -> some View {
        if category == question.answer {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.bamGreen)
        } else if category == selection {
            Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.crakRed)
        }
    }

    private func choiceBackground(_ category: HandCategory) -> Color {
        guard answered else { return Theme.cardBackground }
        if category == question.answer { return Theme.bamGreen.opacity(0.15) }
        if category == selection { return Theme.crakRed.opacity(0.15) }
        return Theme.cardBackground
    }

    private func choiceBorder(_ category: HandCategory) -> Color {
        guard answered else { return Theme.rule }
        if category == question.answer { return Theme.bamGreen.opacity(0.5) }
        if category == selection { return Theme.crakRed.opacity(0.5) }
        return Theme.rule
    }

    private var explanationCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(Theme.gold)
            Text(question.explanation)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
    }

    private var footer: some View {
        Group {
            if answered {
                Button {
                    advance()
                } label: {
                    Text(index + 1 < questions.count ? "Next Rack" : "Finish").primaryCTA()
                }
            } else {
                Text("Rack \(index + 1) of \(questions.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(height: 54)
            }
        }
    }

    private func select(_ category: HandCategory) {
        guard !answered else { return }
        selection = category
        if category == question.answer {
            score += 1
            Haptics.success()
        } else {
            Haptics.error()
        }
    }

    private func advance() {
        if index + 1 < questions.count {
            selection = nil
            index += 1
        } else {
            finished = true
        }
    }
}
