import SwiftUI

enum Theme {
    static let felt = Color(red: 0.13, green: 0.35, blue: 0.28)
    static let feltDeep = Color(red: 0.09, green: 0.26, blue: 0.21)
    static let ivory = Color(red: 0.98, green: 0.96, blue: 0.90)
    static let ivoryShadow = Color(red: 0.85, green: 0.80, blue: 0.68)
    static let crakRed = Color(red: 0.75, green: 0.16, blue: 0.16)
    static let bamGreen = Color(red: 0.12, green: 0.50, blue: 0.30)
    static let dotBlue = Color(red: 0.15, green: 0.32, blue: 0.62)
    static let jokerPurple = Color(red: 0.45, green: 0.25, blue: 0.60)
    static let flowerPink = Color(red: 0.85, green: 0.35, blue: 0.50)
    static let gold = Color(red: 0.85, green: 0.65, blue: 0.25)

    static var background: Color { Color(.systemGroupedBackground) }
    static var cardBackground: Color { Color(.secondarySystemGroupedBackground) }
}

extension View {
    func primaryCTA() -> some View {
        self
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Theme.felt, in: RoundedRectangle(cornerRadius: 16))
    }
}
