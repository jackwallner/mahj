import SwiftUI

struct QuizDrillView: View {
    let drill: Drill
    let questions: [QuizQuestion]

    @State private var index = 0
    @State private var selection: Int?
    @State private var score = 0
    @State private var finished = false

    var body: some View {
        if finished {
            DrillCompleteView(drill: drill, score: score, total: questions.count)
        } else {
            drillBody
        }
    }

    private var question: QuizQuestion { questions[index] }
    private var answered: Bool { selection != nil }

    private var drillBody: some View {
        VStack(spacing: 16) {
            ProgressView(value: Double(index), total: Double(questions.count))
                .tint(Theme.felt)
            ScrollView {
                VStack(spacing: 20) {
                    Text(question.prompt)
                        .font(.title3.bold())
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                    if !question.tiles.isEmpty {
                        TileRackView(tiles: question.tiles, tileWidth: 46)
                    }
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
            ForEach(question.choices.indices, id: \.self) { choiceIndex in
                Button {
                    select(choiceIndex)
                } label: {
                    HStack {
                        Text(question.choices[choiceIndex])
                            .font(.body.weight(.medium))
                            .multilineTextAlignment(.leading)
                        Spacer()
                        if answered {
                            resultIcon(for: choiceIndex)
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity)
                    .background(choiceBackground(choiceIndex), in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .disabled(answered)
            }
        }
    }

    @ViewBuilder
    private func resultIcon(for choiceIndex: Int) -> some View {
        if choiceIndex == question.answerIndex {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.bamGreen)
        } else if choiceIndex == selection {
            Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.crakRed)
        }
    }

    private func choiceBackground(_ choiceIndex: Int) -> Color {
        guard answered else { return Theme.cardBackground }
        if choiceIndex == question.answerIndex { return Theme.bamGreen.opacity(0.15) }
        if choiceIndex == selection { return Theme.crakRed.opacity(0.15) }
        return Theme.cardBackground
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
                    Text(index + 1 < questions.count ? "Next Question" : "Finish").primaryCTA()
                }
            } else {
                Text("Question \(index + 1) of \(questions.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(height: 54)
            }
        }
    }

    private func select(_ choiceIndex: Int) {
        guard !answered else { return }
        selection = choiceIndex
        if choiceIndex == question.answerIndex { score += 1 }
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
