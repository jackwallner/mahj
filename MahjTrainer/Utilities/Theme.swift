import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Warm-modern design system: cream surfaces, jade primary, coral energy,
/// serif display type. Every color adapts to dark mode via dynamic providers.
enum Theme {
    // MARK: Brand

    /// Deep jade: primary actions, progress, selected states.
    static let jade = Color(light: (0.09, 0.42, 0.36), dark: (0.36, 0.71, 0.62))
    /// Terracotta coral, for energy moments: streaks, celebration, badges.
    static let coral = Color(light: (0.86, 0.42, 0.31), dark: (0.94, 0.56, 0.45))
    /// Soft gold: locks, "best value", coach highlights.
    static let gold = Color(light: (0.76, 0.57, 0.18), dark: (0.88, 0.72, 0.38))
    /// Gold for TEXT. The fill gold is about 2.5:1 on cream, under AA for the
    /// small badge and caption text it was used for; this one clears 4.5:1 on
    /// cream and on a gold-tinted pill.
    static let goldText = Color(light: (0.46, 0.32, 0.06), dark: (0.88, 0.72, 0.38))
    /// Plum: Charleston room identity.
    static let plum = Color(light: (0.48, 0.28, 0.52), dark: (0.72, 0.53, 0.76))

    /// An accent color made readable as small TEXT: darker in light mode,
    /// lighter in dark. The fill accents measure about 6:1 on a card, which
    /// Apple's audit fails for thin caption type ("1 free today"); this keeps
    /// the hue and clears it.
    static func readable(_ accent: Color) -> Color {
        #if canImport(UIKit)
        Color(uiColor: UIColor { traits in
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            UIColor(accent).resolvedColor(with: traits).getRed(&r, green: &g, blue: &b, alpha: &a)
            if traits.userInterfaceStyle == .dark {
                return UIColor(red: r + (1 - r) * 0.25, green: g + (1 - g) * 0.25, blue: b + (1 - b) * 0.25, alpha: a)
            }
            return UIColor(red: r * 0.75, green: g * 0.75, blue: b * 0.75, alpha: a)
        })
        #else
        accent
        #endif
    }

    // MARK: Surfaces

    /// Warm cream app background (never pure white / pure black).
    static let background = Color(light: (0.97, 0.945, 0.90), dark: (0.11, 0.10, 0.09))
    /// Raised card surface.
    static let card = Color(light: (1.0, 0.99, 0.965), dark: (0.17, 0.155, 0.14))
    /// Slightly sunken surface for wells inside cards.
    static let well = Color(light: (0.945, 0.915, 0.86), dark: (0.14, 0.13, 0.115))
    /// Hairline stroke on cards.
    static let rule = Color(light: (0.86, 0.82, 0.75), dark: (0.28, 0.26, 0.235))

    // MARK: Ink

    // Contrast is not a style knob here. This app's readers skew 50+ and read
    // it on a couch in bad light, and tertiary ink carries the money disclosure
    // and the swipe instructions. WCAG AA (4.5:1) is the floor, not the target:
    // Apple's accessibility audit measures the drawn glyphs, and thin regular
    // text at 6:1 on cream failed it (release gate, Oct 2026). Secondary sits
    // near 8:1 and tertiary near 6.5:1 on every surface, light and dark.
    // Re-check with a contrast calculator before darkening the cream.
    static let ink = Color(light: (0.16, 0.14, 0.12), dark: (0.94, 0.92, 0.88))
    /// 8.3:1 on the background, 7.7:1 in a well / 9.6:1 dark.
    static let inkSecondary = Color(light: (0.30, 0.275, 0.24), dark: (0.78, 0.75, 0.70))
    /// 6.6:1 on the background, 6.2:1 in a well / 7.6:1 dark.
    static let inkTertiary = Color(light: (0.36, 0.33, 0.29), dark: (0.70, 0.67, 0.62))

    // MARK: Tiles

    static let tileIvory = Color(light: (0.985, 0.965, 0.915), dark: (0.93, 0.90, 0.83))
    static let tileEdge = Color(light: (0.84, 0.79, 0.68), dark: (0.70, 0.65, 0.54))
    static let crakRed = Color(red: 0.72, green: 0.17, blue: 0.16)
    static let bamGreen = Color(red: 0.12, green: 0.47, blue: 0.29)
    static let dotBlue = Color(red: 0.15, green: 0.32, blue: 0.60)
    static let jokerPurple = Color(red: 0.45, green: 0.25, blue: 0.60)
    static let flowerPink = Color(red: 0.80, green: 0.33, blue: 0.47)
    /// The FLOWER caption: the icon's pink measured 3.8:1 on the ivory face.
    static let flowerText = Color(red: 0.62, green: 0.18, blue: 0.32)

    // MARK: Legacy aliases (kept so tile faces read as one system)

    static var felt: Color { jade }
    static var cardBackground: Color { card }
    static var ivory: Color { tileIvory }
    static var ivoryShadow: Color { tileEdge }

    // MARK: Type

    /// Serif display for titles: the "mahj club" voice.
    /// Display type follows the reader's text size, so a title never ends up
    /// smaller than the body copy under it at accessibility sizes. Capped so
    /// a 34pt score does not outgrow its screen.
    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        let scaled = UIFontMetrics(forTextStyle: .title1).scaledValue(for: size)
        return .system(size: min(scaled, size * 1.6), weight: weight, design: .serif)
    }

    /// Label on a filled button. The dark-mode fills are light enough that
    /// white text fell to about 2.5:1, so dark mode uses the background ink.
    static let onFill = Color(light: (1, 1, 1), dark: (0.11, 0.10, 0.09))

    static let cardCorner: CGFloat = 20
    static let deckCorner: CGFloat = 26
    /// Keeps reading and answering comfortable on iPad instead of stretching
    /// phone-sized interactions across the full window.
    static let readableContentWidth: CGFloat = 760
    static let wideContentWidth: CGFloat = 1120
}

/// Room identity: each room keeps its own accent so the four doors feel like
/// four places, not four list rows.
extension Room {
    var accent: Color {
        switch id {
        case "tile-room": return Theme.jade
        case "card-room": return Theme.coral
        case "charleston-room": return Theme.plum
        default: return Theme.gold
        }
    }

    /// Bundled room illustration (see `scripts/generate_room_art.py`). Purely
    /// decorative: never carries information a player has to read.
    var artName: String { "room-\(id)" }
}

/// The membership brand. The RevenueCat entitlement is still `pro`; this is
/// only what players read.
enum Membership {
    static let name = "Mahj+"
}

/// The gold pill that marks anything behind the membership.
struct PlusBadge: View {
    var text: String = Membership.name

    var body: some View {
        Text(text)
            .font(.caption.weight(.heavy))
            .foregroundStyle(Theme.goldText)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Theme.gold.opacity(0.15), in: Capsule())
    }
}

extension Color {
    /// Adaptive color from light/dark RGB triples.
    init(light: (Double, Double, Double), dark: (Double, Double, Double)) {
        #if canImport(UIKit)
        self.init(uiColor: UIColor { traits in
            let c = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: c.0, green: c.1, blue: c.2, alpha: 1)
        })
        #else
        self.init(red: light.0, green: light.1, blue: light.2)
        #endif
    }
}

// MARK: - Shared styles

extension View {
    /// Standard raised card: warm surface, hairline, soft shadow.
    func themedCard(corner: CGFloat = Theme.cardCorner) -> some View {
        self
            .background(Theme.card, in: RoundedRectangle(cornerRadius: corner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .strokeBorder(Theme.rule, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
    }

    func primaryCTA(color: Color = Theme.jade) -> some View {
        self
            .font(.headline)
            .foregroundStyle(Theme.onFill)
            .multilineTextAlignment(.center)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 56)
            .background(color, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: color.opacity(0.35), radius: 8, y: 4)
    }
}

extension EdgeInsets {
    static prefix func - (insets: EdgeInsets) -> EdgeInsets {
        EdgeInsets(top: -insets.top, leading: -insets.leading, bottom: -insets.bottom, trailing: -insets.trailing)
    }
}

extension View {
    /// Inside a small text control's label: grows its tap and accessibility
    /// frame to 44pt. Pair it with `.padding(-insets)` on the control, which
    /// takes the room back out of the layout, so nothing on screen moves.
    func hitPadding(_ insets: EdgeInsets) -> some View {
        padding(insets).contentShape(Rectangle())
    }
}

/// Press-scale feedback for card-shaped buttons.
struct PressableCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        PressableCard(configuration: configuration)
    }

    /// A view, so it can read Reduce Motion: the press dims instead of scaling.
    private struct PressableCard: View {
        let configuration: Configuration
        @Environment(\.accessibilityReduceMotion) private var reduceMotion

        var body: some View {
            configuration.label
                .scaleEffect(configuration.isPressed && !reduceMotion ? 0.975 : 1)
                .opacity(configuration.isPressed && reduceMotion ? 0.85 : 1)
                .animation(reduceMotion ? nil : .spring(response: 0.28, dampingFraction: 0.7), value: configuration.isPressed)
        }
    }
}

// MARK: - Haptics

enum Haptics {
    enum Impact { case soft, light, rigid, heavy }

    /// Settings gate: reads the same key AppSettings writes, defaulting on.
    private static var enabled: Bool {
        UserDefaults.standard.object(forKey: "settings.haptics") as? Bool ?? true
    }

    static func impact(_ style: Impact, intensity: CGFloat = 1.0) {
        #if canImport(UIKit)
        guard enabled else { return }
        let uiStyle: UIImpactFeedbackGenerator.FeedbackStyle
        switch style {
        case .soft: uiStyle = .soft
        case .light: uiStyle = .light
        case .rigid: uiStyle = .rigid
        case .heavy: uiStyle = .heavy
        }
        UIImpactFeedbackGenerator(style: uiStyle).impactOccurred(intensity: intensity)
        #endif
    }

    static func success() {
        #if canImport(UIKit)
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }

    static func error() {
        #if canImport(UIKit)
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        #endif
    }

    /// Grading haptics have to feel like OPPOSITES in the hand, not like two
    /// versions of the same buzz. Apple's `.success` and `.error` notification
    /// patterns are both stutters and are easy to confuse mid-drill, so:
    /// right = a crisp light tap rising into the success chime; wrong = a
    /// single dull heavy thud, no chime, nothing bright about it.
    static func correctAnswer() {
        #if canImport(UIKit)
        guard enabled else { return }
        impact(.light, intensity: 0.75)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 70_000_000)
            success()
        }
        #endif
    }

    static func wrongAnswer() {
        #if canImport(UIKit)
        guard enabled else { return }
        impact(.heavy, intensity: 0.85)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 110_000_000)
            impact(.heavy, intensity: 0.45)
        }
        #endif
    }
}
