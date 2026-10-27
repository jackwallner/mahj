import SwiftUI

/// Pane frames for the unfolded iPhone Duo: Home on the leading side of the
/// fold, the room or drill it opened on the trailing side, so no card
/// straddles the crease. `nil` keeps the single column (every ordinary
/// iPhone, the folded Duo, and the unfolded Duo held in portrait, where each
/// half would be too narrow) and every iPad, which keeps its own two-column
/// Home: a full-screen iPad is just as wide, but it is not a fold.
struct UnfoldedSplit: Equatable, Sendable {
    var primaryWidth: CGFloat
    var secondaryX: CGFloat
    var secondaryWidth: CGFloat

    /// Narrowest pane that still fits the phone layouts of Home and a drill.
    static let minimumPaneWidth: CGFloat = 360

    /// - Parameters:
    ///   - width: the container's width.
    ///   - idiom: the device's; only a phone splits.
    ///   - fold: the vertical fold's leading and trailing edge in the same
    ///     coordinate space, or `nil` when the system reports none.
    static func make(
        width: CGFloat,
        isRegularWidth: Bool,
        idiom: UIUserInterfaceIdiom,
        fold: ClosedRange<CGFloat>?
    ) -> UnfoldedSplit? {
        guard idiom == .phone, isRegularWidth, width >= minimumPaneWidth * 2 else { return nil }
        if let fold,
           fold.lowerBound >= minimumPaneWidth,
           width - fold.upperBound >= minimumPaneWidth {
            return UnfoldedSplit(
                primaryWidth: fold.lowerBound,
                secondaryX: fold.upperBound,
                secondaryWidth: width - fold.upperBound
            )
        }
        let half = (width / 2).rounded(.down)
        return UnfoldedSplit(primaryWidth: half, secondaryX: half, secondaryWidth: width - half)
    }
}

/// What `UnfoldedSplit` is measured from, read off the container.
struct PaneGeometry: Equatable, Sendable {
    var width: CGFloat
    var fold: ClosedRange<CGFloat>?
}

extension GeometryProxy {
    /// The vertical fold's horizontal extent in this proxy's space. Inactive
    /// folds count too, so the panes don't jump while the device opens.
    func verticalFold() -> ClosedRange<CGFloat>? {
        guard #available(iOS 27.1, *) else { return nil }
        let fold = reservedRegions(kind: .division, options: .includeInactive)
            .map(\.frame)
            .first { $0.height > $0.width && $0.minX > 0 && $0.maxX < size.width }
        guard let fold else { return nil }
        return fold.minX...fold.maxX
    }
}

extension EnvironmentValues {
    /// Set on the unfolded Duo's trailing pane, see `trailingPaneEdge()`.
    @Entry var isTrailingPane = false
}

extension View {
    /// iOS 27.1 insets the trailing pane by the Duo's status column the whole
    /// way down, though the clock only sits at the top, so the pane's content
    /// ran off-centre with a dead strip at the screen edge. Ignored per
    /// screen (on the pane's NavigationStack it never reached the screens),
    /// and the content starts below the clock instead.
    func trailingPaneEdge() -> some View {
        modifier(TrailingPaneEdge())
    }
}

private struct TrailingPaneEdge: ViewModifier {
    @Environment(\.isTrailingPane) private var isTrailingPane
    /// From the inline navigation bar's bottom to below the status column's
    /// battery ring (iPhone Duo, iOS 27.1).
    private let statusClearance: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .safeAreaPadding(.top, isTrailingPane ? statusClearance : 0)
            .ignoresSafeArea(.container, edges: isTrailingPane ? .trailing : [])
    }
}
