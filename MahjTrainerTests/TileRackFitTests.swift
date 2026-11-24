import SwiftUI
import XCTest
@testable import MahjTrainer

/// A rack is never wider than the room it is given. With Display Zoom an
/// iPhone 15 Pro is 320pt wide, and a question offers its rack 268pt (16pt
/// drill padding and 10pt pager headroom a side). Seven 44pt tiles drew 344pt
/// there and the scroll view cut tiles off both edges ("text and tiles are
/// constantly cut off", 1-star review, 2026-11-21).
@MainActor
final class TileRackFitTests: XCTestCase {
    private let deal: [Tile] = [
        .c(1), .c(1), .c(2), .c(3), .b(4), .b(5), .b(5),
        .d(7), .d(8), .d(9), .wind(.north), .dragon(.red), .joker,
    ]

    private func size(_ rack: TileRackView, width: CGFloat?) -> CGSize {
        let host = UIHostingController(rootView: rack)
        return host.sizeThatFits(in: CGSize(width: width ?? .greatestFiniteMagnitude, height: .greatestFiniteMagnitude))
    }

    func testARackFitsTheWidthItIsOffered() {
        // Zoomed iPhone question, zoomed iPhone full width, a narrow card.
        for width in [200, 236, 268, 288, 320] as [CGFloat] {
            for (tiles, tileWidth) in [(deal, 44), (deal + [.flower], 40), (deal, 36)] as [([Tile], CGFloat)] {
                let fitted = size(TileRackView(tiles: tiles, tileWidth: tileWidth), width: width)
                XCTAssertLessThanOrEqual(fitted.width, width + 0.5, "\(tiles.count) tiles at \(tileWidth)pt in \(width)pt")
            }
        }
    }

    func testARackThatFitsKeepsItsDesign() {
        // 7 and 6 rows of 44pt tiles with 6pt gaps.
        let fitted = size(TileRackView(tiles: deal, tileWidth: 44), width: 400)
        XCTAssertEqual(fitted.width, 7 * 44 + 6 * 6, accuracy: 0.5)
        XCTAssertEqual(fitted.height, 2 * 44 * 1.35 + 10, accuracy: 0.5)
        // The primer's ViewThatFits reads the ideal size: still the design.
        XCTAssertEqual(size(TileRackView(tiles: deal, tileWidth: 44), width: nil).width, 344, accuracy: 0.5)
    }

    func testANarrowRackWrapsRatherThanShrinkingItsTiles() {
        let fitted = size(TileRackView(tiles: deal, tileWidth: 44), width: 268)
        // Five a row (5, 4, 4): three rows of full-size tiles.
        XCTAssertEqual(fitted.height, 3 * 44 * 1.35 + 2 * 10, accuracy: 0.5)

        let renderer = ImageRenderer(content: TileRackView(tiles: deal, tileWidth: 44)
            .frame(width: 268)
            .padding(26)
            .background(Color.white))
        renderer.scale = 3
        if let image = renderer.uiImage {
            let shot = XCTAttachment(image: image)
            shot.name = "rack-at-268pt-display-zoom"
            shot.lifetime = .keepAlways
            add(shot)
        }
    }

    // Tiles follow the iPhone's text size (2026-11-24, a teacher: tiles too
    // small for kids and older players on a phone).
    func testTilesGrowWithTextSizeAndStopAtTheCap() {
        let sizes = DynamicTypeSize.allCases
        let scales = sizes.map(TileView.scale(for:))
        XCTAssertEqual(scales, scales.sorted(), "never shrinks as text grows")
        XCTAssertEqual(TileView.scale(for: .large), 1)
        XCTAssertEqual(TileView.scale(for: .xSmall), 1, "small text never shrinks a tile")
        XCTAssertEqual(TileView.scaled(44, for: .accessibility5), 61.6, accuracy: 0.01)
        XCTAssertEqual(TileView.scaled(54, for: .accessibility5), TileView.maximumWidth)
    }

    private func size(_ rack: TileRackView, width: CGFloat, typeSize: DynamicTypeSize) -> CGSize {
        let host = UIHostingController(rootView: rack.environment(\.dynamicTypeSize, typeSize))
        return host.sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude))
    }

    func testALargeTextRackStillFitsAZoomedQuestion() {
        for typeSize in DynamicTypeSize.allCases {
            let tile = TileView.scaled(44, for: typeSize)
            let fitted = size(TileRackView(tiles: deal, tileWidth: 44), width: 268, typeSize: typeSize)
            XCTAssertLessThanOrEqual(fitted.width, 268.5, "\(typeSize)")
            // Never a lone tile on its own row: at the cap 13 tiles read 4, 3, 3, 3.
            let rows = Int(((fitted.height + 10) / (tile * 1.35 + 10)).rounded())
            XCTAssertLessThanOrEqual(rows, 4, "\(typeSize)")
        }
        let largest = size(TileRackView(tiles: deal, tileWidth: 44), width: 268, typeSize: .accessibility5)
        XCTAssertEqual(largest.height, 4 * 61.6 * 1.35 + 3 * 10, accuracy: 0.5)
    }
}
