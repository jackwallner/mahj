import SwiftUI

/// Shared question scaffolding: prompt + tiles + choices + explanation, the
/// shape every choice-based drill uses (Quiz, Hand Match, Quick Session).
struct QuestionPager<Choices: View>: View {
    let prompt: String
    let tiles: [Tile]
    let explanation: String
    let answered: Bool
    @ViewBuilder let choices: () -> Choices

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text(prompt)
                    .font(Theme.display(22))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                if !tiles.isEmpty {
                    TileRackView(tiles: tiles, tileWidth: 44)
                }
                choices()
                if answered {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(Theme.gold)
                        Text(explanation)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                }
            }
        }
    }
}

/// The answer buttons every question type shares. On reveal the correct
/// answer LANDS: it pops, glows, and a shine sweeps across it, and the graded
/// state holds until the drill's Next button advances and never auto-skips.
struct ChoiceList: View {
    let labels: [String]
    let selection: Int?
    let answerIndex: Int
    let onPick: (Int) -> Void

    @State private var shineTrigger = 0
    @State private var landed = false
    @State private var shakes: CGFloat = 0

    private var answered: Bool { selection != nil }

    var body: some View {
        VStack(spacing: 10) {
            ForEach(labels.indices, id: \.self) { index in
                row(index)
            }
        }
        .onChange(of: answered) { _, isAnswered in
            guard isAnswered else {
                // New question: reset the celebration state.
                landed = false
                shakes = 0
                return
            }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.5).delay(0.05)) {
                landed = true
            }
            shineTrigger += 1
            if selection != answerIndex {
                withAnimation(.linear(duration: 0.4)) { shakes = 2 }
            }
        }
    }

    private func row(_ index: Int) -> some View {
        let isAnswer = index == answerIndex
        let isMiss = answered && index == selection && !isAnswer
        return Button {
            guard !answered else { return }
            onPick(index)
        } label: {
            HStack {
                Text(labels[index])
                    .font(.body.weight(answered && isAnswer ? .semibold : .medium))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.leading)
                Spacer()
                if answered {
                    if isAnswer {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.body.weight(.bold))
                            .foregroundStyle(Theme.bamGreen)
                            .scaleEffect(landed ? 1.2 : 0.4)
                    } else if isMiss {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.crakRed)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(background(index), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(border(index), lineWidth: answered && isAnswer ? 2.5 : 1)
            )
            .shine(trigger: answered && isAnswer ? shineTrigger : 0)
            .winGlow(Theme.bamGreen, active: answered && isAnswer && landed)
            .scaleEffect(answered && isAnswer && landed ? 1.05 : 1)
            .modifier(ShakeEffect(travels: isMiss ? shakes : 0))
            .opacity(answered && !isAnswer && !isMiss ? 0.55 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: answered)
        }
        .buttonStyle(.plain)
        .disabled(answered)
    }

    private func background(_ index: Int) -> Color {
        guard answered else { return Theme.card }
        if index == answerIndex { return Theme.bamGreen.opacity(0.18) }
        if index == selection { return Theme.crakRed.opacity(0.15) }
        return Theme.card
    }

    private func border(_ index: Int) -> Color {
        guard answered else { return Theme.rule }
        if index == answerIndex { return Theme.bamGreen.opacity(0.6) }
        if index == selection { return Theme.crakRed.opacity(0.5) }
        return Theme.rule
    }
}
