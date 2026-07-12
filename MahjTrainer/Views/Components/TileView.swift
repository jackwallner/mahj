import SwiftUI

/// Renders a single American mahj tile. Text-forward on purpose: US sets
/// literally print N/E/W/S, F, and J, so beginners learn the real markings.
struct TileView: View {
    let tile: Tile
    var width: CGFloat = 44

    private var height: CGFloat { width * 1.35 }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: width * 0.16)
                .fill(Theme.ivory)
                .shadow(color: .black.opacity(0.25), radius: 1.5, y: 1.5)
            RoundedRectangle(cornerRadius: width * 0.16)
                .strokeBorder(Theme.ivoryShadow, lineWidth: 1)
            face
        }
        .frame(width: width, height: height)
        .accessibilityLabel(tile.spokenName)
    }

    @ViewBuilder
    private var face: some View {
        switch tile {
        case .suited(let rank, let suit):
            VStack(spacing: width * 0.02) {
                Text("\(rank)")
                    .font(.system(size: width * 0.5, weight: .bold, design: .serif))
                    .foregroundStyle(suitColor(suit))
                suitGlyph(suit)
            }
        case .wind(let wind):
            VStack(spacing: width * 0.02) {
                Text(wind.letter)
                    .font(.system(size: width * 0.52, weight: .bold, design: .serif))
                    .foregroundStyle(.black.opacity(0.85))
                caption("WIND", color: .black.opacity(0.5))
            }
        case .dragon(.red):
            VStack(spacing: width * 0.02) {
                Text("中")
                    .font(.system(size: width * 0.5, weight: .bold))
                    .foregroundStyle(Theme.crakRed)
                caption("RED", color: Theme.crakRed)
            }
        case .dragon(.green):
            VStack(spacing: width * 0.02) {
                Text("發")
                    .font(.system(size: width * 0.5, weight: .bold))
                    .foregroundStyle(Theme.bamGreen)
                caption("GREEN", color: Theme.bamGreen)
            }
        case .dragon(.soap):
            VStack(spacing: width * 0.06) {
                RoundedRectangle(cornerRadius: width * 0.06)
                    .strokeBorder(Theme.dotBlue, lineWidth: width * 0.055)
                    .frame(width: width * 0.5, height: width * 0.62)
                caption("SOAP", color: Theme.dotBlue)
            }
        case .flower:
            VStack(spacing: width * 0.02) {
                Image(systemName: "camera.macro")
                    .font(.system(size: width * 0.42, weight: .semibold))
                    .foregroundStyle(Theme.flowerPink)
                caption("FLOWER", color: Theme.flowerPink)
            }
        case .joker:
            VStack(spacing: width * 0.02) {
                Image(systemName: "theatermasks.fill")
                    .font(.system(size: width * 0.4, weight: .semibold))
                    .foregroundStyle(Theme.jokerPurple)
                caption("JOKER", color: Theme.jokerPurple)
            }
        }
    }

    private func caption(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: width * 0.16, weight: .heavy))
            .foregroundStyle(color)
    }

    private func suitColor(_ suit: Suit) -> Color {
        switch suit {
        case .crak: return Theme.crakRed
        case .bam: return Theme.bamGreen
        case .dot: return Theme.dotBlue
        }
    }

    @ViewBuilder
    private func suitGlyph(_ suit: Suit) -> some View {
        switch suit {
        case .crak:
            Text("萬")
                .font(.system(size: width * 0.3, weight: .semibold))
                .foregroundStyle(Theme.crakRed)
        case .bam:
            HStack(spacing: width * 0.07) {
                ForEach(0..<3, id: \.self) { _ in
                    Capsule()
                        .fill(Theme.bamGreen)
                        .frame(width: width * 0.09, height: width * 0.3)
                }
            }
        case .dot:
            HStack(spacing: width * 0.06) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle()
                        .strokeBorder(Theme.dotBlue, lineWidth: width * 0.05)
                        .frame(width: width * 0.16, height: width * 0.16)
                }
            }
        }
    }
}

/// A wrapping row of tiles, racked in display order.
struct TileRackView: View {
    let tiles: [Tile]
    var tileWidth: CGFloat = 44
    var highlightedIndices: Set<Int> = []
    var onTap: ((Int) -> Void)?

    private let columns = 7

    var body: some View {
        let rows = tiles.enumerated().map { (index: $0.offset, tile: $0.element) }
            .chunked(into: columns)
        VStack(spacing: 10) {
            ForEach(0..<rows.count, id: \.self) { rowIndex in
                HStack(spacing: 6) {
                    ForEach(rows[rowIndex], id: \.index) { item in
                        tileCell(item.index, item.tile)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func tileCell(_ index: Int, _ tile: Tile) -> some View {
        let selected = highlightedIndices.contains(index)
        TileView(tile: tile, width: tileWidth)
            .overlay {
                if selected {
                    RoundedRectangle(cornerRadius: tileWidth * 0.16)
                        .strokeBorder(Theme.gold, lineWidth: 3)
                }
            }
            .offset(y: selected ? -8 : 0)
            .onTapGesture { onTap?(index) }
            .animation(.spring(duration: 0.25), value: selected)
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
