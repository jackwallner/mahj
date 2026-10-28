import SwiftUI

/// Renders a single American mahj tile. Text-forward on purpose: US sets
/// literally print N/E/W/S, F, and J, so beginners learn the real markings.
struct TileView: View {
    let tile: Tile
    var width: CGFloat = 44
    /// Position-stable handle for UI tests. It must be set HERE, alongside the
    /// accessibility label, because that is what makes this an accessibility
    /// element: applied to the wrapper in `TileRackView` instead, SwiftUI
    /// collapses it and the identifier never reaches the tree.
    var identifier: String?
    /// What tapping this tile does, if anything. It lives here for the same
    /// reason the identifier does: the action has to land on the SAME element
    /// as the label, or VoiceOver reads a tile name with nothing to activate.
    /// Play a Hand is twelve taps long, so a tile that cannot be activated
    /// makes the whole mode unusable rather than one drill awkward.
    var action: (() -> Void)?
    /// Whether this tile is currently picked out (the tile just drawn, or a
    /// selection). Announced, not just drawn.
    var isSelected = false

    private var height: CGFloat { width * 1.35 }

    @ViewBuilder
    var body: some View {
        if let action {
            tileBody.accessibilityAction(.default, action)
        } else {
            tileBody
        }
    }

    private var tileBody: some View {
        ZStack {
            RoundedRectangle(cornerRadius: width * 0.16)
                .fill(Theme.ivory)
                .shadow(color: .black.opacity(0.25), radius: 1.5, y: 1.5)
            RoundedRectangle(cornerRadius: width * 0.16)
                .strokeBorder(Theme.ivoryShadow, lineWidth: 1)
            face
        }
        .frame(width: width, height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(tile.spokenName)
        .accessibilityIdentifier(identifier ?? "")
        .accessibilityAddTraits(accessibilityTraits)
        .accessibilityHint(action == nil ? "" : String(localized: "Double tap to choose this tile"))
    }

    private var accessibilityTraits: AccessibilityTraits {
        var traits = AccessibilityTraits()
        if action != nil { traits.insert(.isButton) }
        if isSelected { traits.insert(.isSelected) }
        return traits
    }

    @ViewBuilder
    private var face: some View {
        switch tile {
        case .suited(let rank, .crak):
            // Real crak tiles read numeral-over-萬; no pips to count.
            VStack(spacing: width * 0.02) {
                Text("\(rank)")
                    .font(.system(size: width * 0.5, weight: .bold, design: .serif))
                    .foregroundStyle(Theme.crakRed)
                Text(verbatim: "萬")
                    .font(.system(size: width * 0.3, weight: .semibold))
                    .foregroundStyle(Theme.crakRed)
            }
        case .suited(let rank, let suit):
            // Dots and bams carry rank-accurate pips: a 9 shows 9 marks.
            VStack(spacing: width * 0.06) {
                Text("\(rank)")
                    .font(.system(size: width * 0.3, weight: .bold, design: .serif))
                    .foregroundStyle(suitColor(suit))
                pipBlock(rank: rank, suit: suit)
            }
        case .wind(let wind):
            VStack(spacing: width * 0.02) {
                Text(wind.letter)
                    .font(.system(size: width * 0.52, weight: .bold, design: .serif))
                    .foregroundStyle(.black.opacity(0.85))
                caption(String(localized: "WIND"), color: .black.opacity(0.66))
            }
        case .dragon(.red):
            VStack(spacing: width * 0.02) {
                Text(verbatim: "中")
                    .font(.system(size: width * 0.5, weight: .bold))
                    .foregroundStyle(Theme.crakRed)
                caption(String(localized: "RED"), color: Theme.crakRed)
            }
        case .dragon(.green):
            VStack(spacing: width * 0.02) {
                Text(verbatim: "發")
                    .font(.system(size: width * 0.5, weight: .bold))
                    .foregroundStyle(Theme.bamGreen)
                caption(String(localized: "GREEN"), color: Theme.bamGreen)
            }
        case .dragon(.soap):
            VStack(spacing: width * 0.06) {
                RoundedRectangle(cornerRadius: width * 0.06)
                    .strokeBorder(Theme.dotBlue, lineWidth: width * 0.055)
                    .frame(width: width * 0.5, height: width * 0.62)
                caption(String(localized: "SOAP"), color: Theme.dotBlue)
            }
        case .flower:
            VStack(spacing: width * 0.02) {
                Image(systemName: "camera.macro")
                    .font(.system(size: width * 0.42, weight: .semibold))
                    .foregroundStyle(Theme.flowerPink)
                caption(String(localized: "FLOWER"), color: Theme.flowerText)
            }
        case .joker:
            VStack(spacing: width * 0.02) {
                Image(systemName: "theatermasks.fill")
                    .font(.system(size: width * 0.4, weight: .semibold))
                    .foregroundStyle(Theme.jokerPurple)
                caption(String(localized: "JOKER"), color: Theme.jokerPurple)
            }
        }
    }

    /// The tile's word (WIND, SOAP, JOKER...) is how a beginner learns which
    /// dragon goes with which suit, so it has a legibility FLOOR. A pure
    /// fraction of the tile width put it at ~7pt on the 44pt tiles the drills
    /// actually use, which is unreadable for the players this app is for.
    private func caption(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: max(9.5, width * 0.16), weight: .heavy))
            // One line always: on the small review tiles GREEN broke as GREE / N.
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .foregroundStyle(color)
            // Inset from the tile's edge, or FLOWER filled the whole 44 pt
            // face and touched both sides before it would scale.
            .padding(.horizontal, width * 0.08)
    }

    private func suitColor(_ suit: Suit) -> Color {
        switch suit {
        case .crak: return Theme.crakRed
        case .bam: return Theme.bamGreen
        case .dot: return Theme.dotBlue
        }
    }

    /// Classic pip arrangements, top row first (5 is the quincunx, 9 the 3x3).
    private func pipRows(for rank: Int) -> [Int] {
        switch rank {
        case 1: return [1]
        case 2: return [2]
        case 3: return [3]
        case 4: return [2, 2]
        case 5: return [2, 1, 2]
        case 6: return [3, 3]
        case 7: return [2, 3, 2]
        case 8: return [3, 2, 3]
        default: return [3, 3, 3]
        }
    }

    @ViewBuilder
    private func pipBlock(rank: Int, suit: Suit) -> some View {
        let rows = pipRows(for: rank)
        let pip = width * (rows.count == 1 ? 0.24 : rows.count == 2 ? 0.19 : 0.145)
        VStack(spacing: pip * 0.28) {
            ForEach(0..<rows.count, id: \.self) { row in
                HStack(spacing: pip * 0.32) {
                    ForEach(0..<rows[row], id: \.self) { _ in
                        pipMark(suit: suit, size: pip)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func pipMark(suit: Suit, size: CGFloat) -> some View {
        switch suit {
        case .dot:
            Circle()
                .strokeBorder(Theme.dotBlue, lineWidth: size * 0.28)
                .frame(width: size, height: size)
        case .bam:
            Capsule()
                .fill(Theme.bamGreen)
                .frame(width: size * 0.45, height: size * 1.3)
        case .crak:
            EmptyView() // craks never render pips
        }
    }
}

/// A wrapping row of tiles, racked in display order.
struct TileRackView: View {
    let tiles: [Tile]
    var tileWidth: CGFloat = 44
    var highlightedIndices: Set<Int> = []
    var onTap: ((Int) -> Void)?
    /// How a tile joining the rack arrives. Play a Hand drops a drawn tile in
    /// once its neighbours have moved aside (`TileRackView.dropIn`); a whole
    /// new deal must not wait, or only the tiles both deals share show first.
    var tileInsertion: AnyTransition = .opacity
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    static let dropIn = AnyTransition.offset(y: -10).combined(with: .opacity)
        .animation(.easeOut(duration: 0.2).delay(0.22))

    private let columns = 7

    var body: some View {
        // Rows are balanced rather than filled: eight tiles split 4 and 4, not
        // 7 and a lone tile. A full 13-tile rack still reads 7 and 6.
        let rowCount = max(1, (tiles.count + columns - 1) / columns)
        let perRow = max(1, (tiles.count + rowCount - 1) / rowCount)
        // Each tile is keyed by what it is (and which copy), never by its
        // position, and every row shares one layout. Keyed by position, a
        // throw or a draw left each slot's outline sliding to its new place
        // while the face inside swapped to a different tile, and a tile that
        // changed rows faded out of one and into the other (Play a Hand,
        // 2026-10-19).
        BalancedRowsLayout(perRow: perRow, spacing: 6, rowSpacing: 10) {
            ForEach(Self.keyed(tiles), id: \.key) { item in
                tileCell(item.index, item.tile)
            }
        }
    }

    private struct TileKey: Hashable {
        let tile: Tile
        let copy: Int
    }

    private static func keyed(_ tiles: [Tile]) -> [(key: TileKey, index: Int, tile: Tile)] {
        var copies: [Tile: Int] = [:]
        return tiles.enumerated().map { index, tile in
            let copy = copies[tile, default: 0]
            copies[tile] = copy + 1
            return (TileKey(tile: tile, copy: copy), index, tile)
        }
    }

    @ViewBuilder
    private func tileCell(_ index: Int, _ tile: Tile) -> some View {
        let selected = highlightedIndices.contains(index)
        TileView(
            tile: tile,
            width: tileWidth,
            identifier: "rack-tile-\(index)",
            action: onTap.map { tap in { tap(index) } },
            isSelected: selected
        )
            // Always present, only its opacity changes: a removed outline
            // stayed behind fading at the old spot while its tile slid away.
            .overlay {
                RoundedRectangle(cornerRadius: tileWidth * 0.16)
                    .strokeBorder(Theme.gold, lineWidth: 3)
                    .opacity(selected ? 1 : 0)
            }
            .offset(y: selected ? -8 : 0)
            .onTapGesture { onTap?(index) }
            .animation(reduceMotion ? nil : .spring(duration: 0.25), value: selected)
            // A thrown tile leaves at once: fading, it sat at its old spot
            // while the rest of the rack slid across it.
            .transition(.asymmetric(insertion: reduceMotion ? .identity : tileInsertion, removal: .identity))
    }
}

/// Rows of `perRow`, each centred, in one container so a tile moving to
/// another row slides there instead of fading out and back in.
private struct BalancedRowsLayout: Layout {
    let perRow: Int
    let spacing: CGFloat
    let rowSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = rowSizes(subviews)
        let width = rows.map(\.width).max() ?? 0
        let height = rows.map(\.height).reduce(0, +) + rowSpacing * CGFloat(max(0, rows.count - 1))
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = rowSizes(subviews)
        var y = bounds.minY
        for (rowIndex, row) in rows.enumerated() {
            var x = bounds.midX - row.width / 2
            for index in row.range {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(
                    at: CGPoint(x: x, y: y + (row.height - size.height) / 2),
                    proposal: ProposedViewSize(size)
                )
                x += size.width + spacing
            }
            y += row.height + (rowIndex < rows.count - 1 ? rowSpacing : 0)
        }
    }

    private func rowSizes(_ subviews: Subviews) -> [(range: Range<Int>, width: CGFloat, height: CGFloat)] {
        stride(from: 0, to: subviews.count, by: max(1, perRow)).map { start in
            let range = start..<min(start + max(1, perRow), subviews.count)
            let sizes = range.map { subviews[$0].sizeThatFits(.unspecified) }
            let width = sizes.map(\.width).reduce(0, +) + spacing * CGFloat(max(0, sizes.count - 1))
            return (range, width, sizes.map(\.height).max() ?? 0)
        }
    }
}
