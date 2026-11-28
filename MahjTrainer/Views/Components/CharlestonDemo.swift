import SwiftUI

/// The Charleston from above, on a loop: four seats each pass three tiles to
/// the right, then across, then to the left, all at once, the way a table
/// does it. Your seat is the jade rack at the bottom and your three tiles go
/// face up, so the first pass shows the page's example tiles leaving you.
///
/// Drawn in code (a few constants of timing and seat geometry), so it costs
/// no assets and stays sharp at any size. Directions are physical, not
/// reading order: right is the seat on your right in every language.
/// Under Reduce Motion the primer shows its plain tile row instead.
struct CharlestonDemo: View {
    /// What you pass on each of the three passes; the first is the page's
    /// own example. Original tiles, never a card hand.
    let passes: [[Tile]]
    var height: CGFloat = 168

    @Environment(\.scenePhase) private var scenePhase
    @State private var startedAt = Date()

    init(passing first: [Tile], height: CGFloat = 168) {
        passes = [
            Array(first.prefix(3)),
            [.c(7), .wind(.south), .d(2)],
            [.b(4), .dragon(.green), .c(1)],
        ]
        self.height = height
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: scenePhase != .active)) { timeline in
            let t = timeline.date.timeIntervalSince(startedAt)
            Canvas { ctx, size in
                draw(ctx, size: size, t: t)
            } symbols: {
                ForEach(passes.indices, id: \.self) { pass in
                    ForEach(passes[pass].indices, id: \.self) { slot in
                        TileView(tile: passes[pass][slot], width: Self.tileWidth)
                            .environment(\.dynamicTypeSize, .large)
                            .tag(Self.tag(pass, slot))
                    }
                }
            }
        }
        .frame(width: height * 1.5, height: height)
        // The page's title and body already say what moves; the drawing adds
        // nothing a screen reader could use.
        .accessibilityHidden(true)
        // Lets the fleet's idle-screen check skip it: it moves on purpose.
        .accessibilityIdentifier("charleston-demo")
    }

    // MARK: - Timing

    nonisolated static let tileWidth: CGFloat = 20
    private nonisolated static let look = 0.7
    private nonisolated static let fly = 1.0
    private nonisolated static let settle = 0.45
    private nonisolated static var pass: Double { look + fly + settle }
    /// One loop: right, across, left, then a beat before it starts over.
    nonisolated static var cycle: Double { pass * 3 + 0.6 }

    private static func tag(_ pass: Int, _ slot: Int) -> Int { pass * 3 + slot }

    // MARK: - Seats

    private enum Seat: CaseIterable { case south, east, north, west }

    /// Who each seat hands its tiles to on pass 0 (right), 1 (across), 2 (left).
    private static func target(of seat: Seat, pass: Int) -> Seat {
        let order: [Seat] = [.south, .east, .north, .west]
        let i = order.firstIndex(of: seat) ?? 0
        return order[(i + [1, 2, 3][pass]) % 4]
    }

    private struct Table {
        let size: CGSize
        var cloth: CGRect { CGRect(origin: .zero, size: size).insetBy(dx: 2, dy: 2) }
        var center: CGPoint { CGPoint(x: size.width / 2, y: size.height / 2) }

        /// The middle of the three tiles waiting in front of a rack.
        func stack(_ seat: Seat) -> CGPoint {
            let dx = size.width * 0.31, dy = size.height * 0.27
            switch seat {
            case .south: return CGPoint(x: center.x, y: center.y + dy)
            case .north: return CGPoint(x: center.x, y: center.y - dy)
            case .east: return CGPoint(x: center.x + dx, y: center.y)
            case .west: return CGPoint(x: center.x - dx, y: center.y)
            }
        }

        func rack(_ seat: Seat) -> CGRect {
            let long = size.width * 0.42, thick: CGFloat = 7
            let edge: CGFloat = 9
            switch seat {
            case .south: return CGRect(x: center.x - long / 2, y: size.height - edge - thick, width: long, height: thick)
            case .north: return CGRect(x: center.x - long / 2, y: edge, width: long, height: thick)
            case .east: return CGRect(x: size.width - edge - thick, y: center.y - long * 0.4, width: thick, height: long * 0.8)
            case .west: return CGRect(x: edge, y: center.y - long * 0.4, width: thick, height: long * 0.8)
            }
        }
    }

    // MARK: - Drawing

    private func draw(_ ctx: GraphicsContext, size: CGSize, t: Double) {
        let table = Table(size: size)
        ctx.fill(Path(roundedRect: table.cloth, cornerRadius: 18), with: .color(Theme.jade.opacity(0.10)))
        for seat in Seat.allCases {
            let color = seat == .south ? Theme.jade : Theme.inkTertiary.opacity(0.45)
            ctx.fill(Path(roundedRect: table.rack(seat), cornerRadius: 3.5), with: .color(color))
        }

        let local = max(0, t).truncatingRemainder(dividingBy: Self.cycle)
        let pass = min(2, Int(local / Self.pass))
        let phase = local - Double(pass) * Self.pass
        let resting = local >= Self.pass * 3

        for seat in Seat.allCases {
            let from = table.stack(seat)
            let to = table.stack(Self.target(of: seat, pass: pass))
            for slot in 0..<3 {
                let progress = resting ? 1 : Self.flight(phase, slot: slot)
                let point = Self.arc(from: from, to: to, progress: progress, bulge: size.height * 0.07)
                let spread = CGFloat(slot - 1) * (Self.tileWidth + 3)
                let center = CGPoint(x: point.x + spread, y: point.y)
                let yours = seat == .south && progress < 1 && !resting
                // Your tiles come up face up while you look, and stay face up
                // until they land in front of someone else.
                let reveal = yours ? Self.ease(min(1, phase / (Self.look * 0.5))) : 0
                drawTile(ctx, at: center, faceUp: reveal, symbol: Self.tag(pass, slot))
            }
        }
    }

    /// 0 before the tile leaves, 1 once it lands. The three tiles leave a
    /// beat apart, so the pass reads as three tiles, not one block.
    private static func flight(_ phase: Double, slot: Int) -> Double {
        let start = look + Double(slot) * 0.08
        return ease((phase - start) / (fly - 0.16))
    }

    /// Opposite seats pass straight through the middle at the same moment,
    /// so every path bows a little to its left to keep the crossing tiles
    /// apart.
    private static func arc(from: CGPoint, to: CGPoint, progress: Double, bulge: CGFloat) -> CGPoint {
        let p = CGFloat(progress)
        let dx = to.x - from.x, dy = to.y - from.y
        let length = max(1, (dx * dx + dy * dy).squareRoot())
        let lift = bulge * 4 * p * (1 - p)
        return CGPoint(x: from.x + dx * p + dy / length * lift, y: from.y + dy * p - dx / length * lift)
    }

    private static func ease(_ x: Double) -> Double {
        let x = min(max(x, 0), 1)
        return x * x * (3 - 2 * x)
    }

    private func drawTile(_ ctx: GraphicsContext, at center: CGPoint, faceUp: Double, symbol: Int) {
        let w = Self.tileWidth, h = w * 1.35
        let rect = CGRect(x: center.x - w / 2, y: center.y - h / 2, width: w, height: h)
        if faceUp < 1 {
            var back = ctx
            back.opacity = 1 - faceUp
            back.fill(Path(roundedRect: rect, cornerRadius: 4), with: .color(Theme.jade))
            back.stroke(Path(roundedRect: rect.insetBy(dx: 2.5, dy: 2.5), cornerRadius: 2.5),
                        with: .color(Theme.ivory.opacity(0.55)), lineWidth: 1)
        }
        if faceUp > 0, let face = ctx.resolveSymbol(id: symbol) {
            var front = ctx
            front.opacity = faceUp
            front.draw(face, at: center)
        }
    }
}

#Preview {
    CharlestonDemo(passing: [.b(1), .d(9), .wind(.west)])
        .padding()
        .background(Theme.card)
}
