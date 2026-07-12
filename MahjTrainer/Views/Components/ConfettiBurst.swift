import SwiftUI

/// A one-shot confetti burst. Bump `trigger` to fire; particles launch from
/// `origin` (unit coordinates), tumble under gravity, and fade. Drawn with
/// Canvas so a burst costs nothing after it ends.
struct ConfettiBurst: View {
    var trigger: Int
    var origin: UnitPoint = .center
    var particleCount: Int = 26

    @State private var firedAt: Date?
    @State private var seed: Int = 0

    private static let colors: [Color] = [
        Theme.jade, Theme.coral, Theme.gold, Theme.plum, Theme.tileIvory,
    ]
    private static let duration: Double = 1.4

    var body: some View {
        Group {
            if let firedAt {
                TimelineView(.animation) { context in
                    Canvas { canvas, size in
                        let t = context.date.timeIntervalSince(firedAt)
                        guard t < Self.duration else { return }
                        draw(in: &canvas, size: size, time: t)
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, _ in
            seed = trigger
            firedAt = Date()
        }
    }

    private func draw(in canvas: inout GraphicsContext, size: CGSize, time: Double) {
        let start = CGPoint(x: origin.x * size.width, y: origin.y * size.height)
        var random = SeededRandom(seed: UInt64(bitPattern: Int64(seed &* 7919 &+ 13)))
        for index in 0..<particleCount {
            let angle = random.next(in: -Double.pi, -0.15 * Double.pi) + random.next(in: -0.35, 0.35)
            let speed = random.next(in: 180, 420)
            let gravity = 640.0
            let x = start.x + CGFloat(cos(angle) * speed * time)
            let y = start.y + CGFloat(sin(angle) * speed * time + 0.5 * gravity * time * time)
            guard y < size.height + 20 else { continue }

            let life = time / Self.duration
            let fade = life < 0.7 ? 1.0 : max(0, 1 - (life - 0.7) / 0.3)
            let spin = random.next(in: 2, 9) * time * (index.isMultiple(of: 2) ? 1 : -1)
            let w = random.next(in: 5, 9)
            let h = random.next(in: 8, 13)

            var piece = canvas
            piece.translateBy(x: x, y: y)
            piece.rotate(by: .radians(spin))
            piece.opacity = fade
            let rect = CGRect(x: -w / 2, y: -h / 2, width: w, height: h)
            piece.fill(
                Path(roundedRect: rect, cornerRadius: 1.5),
                with: .color(Self.colors[index % Self.colors.count])
            )
        }
    }
}

/// Tiny deterministic generator so a burst renders identically every frame.
private struct SeededRandom {
    private var state: UInt64

    init(seed: UInt64) { state = seed == 0 ? 0x9E3779B9 : seed }

    private mutating func nextRaw() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }

    mutating func next(in low: Double, _ high: Double) -> Double {
        low + (high - low) * (Double(nextRaw() % 10_000) / 10_000)
    }
}
