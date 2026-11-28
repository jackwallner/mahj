import SwiftUI

/// Every push, including room drills, belongs to the same value path. Mixing
/// view-based links with a bound path lets a deep link discard the open views.
@MainActor
final class ScreenNavigation: ObservableObject {
    @Published var path: [NavigationScreen] = []

    var activeRoute: AppDestination? { path.last { $0.route != nil }?.route }
}

struct NavigationScreen: Hashable {
    let id: String
    let view: AnyView
    let route: AppDestination?
    let hidesBackButtonInPane: Bool
    private let token = UUID()

    init(id: String = "", view: AnyView, route: AppDestination? = nil, hidesBackButtonInPane: Bool = false) {
        self.id = id
        self.view = view
        self.route = route
        self.hidesBackButtonInPane = hidesBackButtonInPane
    }

    static func == (lhs: NavigationScreen, rhs: NavigationScreen) -> Bool { lhs.token == rhs.token }
    func hash(into hasher: inout Hasher) { hasher.combine(token) }
}

/// The standard link appearance, backed by a value rather than an untracked
/// view push. Its destination is held by the path while another screen is up.
struct ScreenLink<Destination: View, Label: View>: View {
    private let destination: Destination
    private let label: Label

    init(@ViewBuilder destination: () -> Destination, @ViewBuilder label: () -> Label) {
        self.destination = destination()
        self.label = label()
    }

    var body: some View {
        NavigationLink(value: NavigationScreen(view: AnyView(destination))) { label }
    }
}
