import SwiftUI

/// A `ScrollView` that CENTERS its content when the content is shorter than
/// the viewport, and scrolls exactly like a plain one when it is taller.
///
/// Drills are scroll views because a graded question with its coaching note can
/// outgrow an iPhone. On an iPad that same question fills a third of the screen
/// and a bare `ScrollView` pins it to the top, leaving a field of empty cream
/// under it, which is what the 1.2 iPad screenshots showed.
///
/// The mechanic is `minHeight`, not `height`: content taller than the viewport
/// keeps its natural size and scrolls, so nothing about the iPhone layout, the
/// answer-glow headroom, or `scrollTo` changes.
struct CenteringScrollView<Content: View>: View {
    /// The scroll target (from a `scrollTargetLayout` in the content) held
    /// at the top of the viewport, clamped by the scroll range, while the
    /// content grows. Nil leaves the scroll where the player put it.
    var pinned: Binding<String?>? = nil
    @ViewBuilder let content: () -> Content

    var body: some View {
        GeometryReader { viewport in
            ScrollView {
                content()
                    // maxWidth as well as minHeight. A plain ScrollView centres
                    // narrow content across the scroll axis for you; once the
                    // content carries an explicit frame it stops doing that and
                    // the whole question slides to the leading edge.
                    .frame(
                        maxWidth: .infinity,
                        minHeight: viewport.size.height,
                        alignment: .center
                    )
            }
            .modifier(PinnedTarget(id: pinned))
        }
    }
}

private struct PinnedTarget: ViewModifier {
    let id: Binding<String?>?

    func body(content: Content) -> some View {
        if let id {
            content.scrollPosition(id: id, anchor: .top)
        } else {
            content
        }
    }
}
