import SwiftUI

struct FlashcardDrillView: View {
    let drill: Drill
    let cards: [Flashcard]

    @State private var index = 0
    @State private var isFlipped = false
    @State private var finished = false

    var body: some View {
        if finished {
            DrillCompleteView(drill: drill, score: nil, total: cards.count)
        } else {
            drillBody
        }
    }

    private var drillBody: some View {
        VStack(spacing: 20) {
            ProgressView(value: Double(index), total: Double(cards.count))
                .tint(Theme.felt)
            Spacer()
            flipCard
            Spacer()
            footer
        }
        .padding()
        .background(Theme.background)
        .navigationTitle(drill.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var card: Flashcard { cards[index] }

    private var flipCard: some View {
        ZStack {
            cardFace(front: true)
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            cardFace(front: false)
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 380)
        .onTapGesture {
            withAnimation(.spring(duration: 0.45)) { isFlipped.toggle() }
        }
        .accessibilityIdentifier("flashcard")
    }

    private func cardFace(front: Bool) -> some View {
        VStack(spacing: 18) {
            if front {
                Text(card.frontTitle)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                if !card.frontTiles.isEmpty {
                    TileRackView(tiles: card.frontTiles, tileWidth: 48)
                }
                if let subtitle = card.frontSubtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text(card.backTitle)
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)
                Text(card.backBody)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(front ? Theme.cardBackground : Theme.felt.opacity(0.08))
                .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(front ? Color.clear : Theme.felt.opacity(0.3), lineWidth: 1.5)
        )
    }

    private var footer: some View {
        VStack(spacing: 10) {
            if isFlipped {
                Button {
                    advance()
                } label: {
                    Text(index + 1 < cards.count ? "Next Card" : "Finish").primaryCTA()
                }
            } else {
                Button {
                    withAnimation(.spring(duration: 0.45)) { isFlipped = true }
                } label: {
                    Text("Flip Card").primaryCTA()
                }
            }
            Text("Card \(index + 1) of \(cards.count)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func advance() {
        if index + 1 < cards.count {
            isFlipped = false
            index += 1
        } else {
            finished = true
        }
    }
}
