import SwiftUI

/// Mahj Minutes played before 1.4.2, when the Minute was its own members'
/// set. Since then each day's Minute is the month's challenge round; these
/// stay readable so nobody's history vanishes.
struct MahjMinuteHistoryView: View {
    @StateObject private var store = MahjMinuteStore.shared

    var body: some View {
        let results = store.results.values.sorted { $0.dayKey > $1.dayKey }
        ScrollView {
            VStack(spacing: 0) {
                ForEach(results) { result in
                    NavigationLink {
                        MahjMinuteResultView(result: result)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Theme.jade)
                                .frame(width: 28)
                                .accessibilityHidden(true)
                            Text(result.completedAt, format: .dateTime.month(.abbreviated).day().year())
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Theme.ink)
                            Spacer()
                            Text("\(result.score)/\(result.total)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.jade)
                                .monospacedDigit()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Theme.inkTertiary)
                                .accessibilityHidden(true)
                        }
                        .padding(14)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    if result.id != results.last?.id {
                        Divider().overlay(Theme.rule)
                    }
                }
            }
            .themedCard(corner: 16)
            .padding()
            .frame(maxWidth: Theme.readableContentWidth)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.background)
        .navigationTitle("Earlier Mahj Minutes")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// One earlier Minute: its score and how each skill went.
struct MahjMinuteResultView: View {
    let result: MahjMinuteResult

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                scoreCard
                breakdown
            }
            .padding()
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.background)
        .navigationTitle("Mahj Minute")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var scoreCard: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Theme.jade.opacity(0.12))
                    .frame(width: 122, height: 122)
                VStack(spacing: 1) {
                    Text("\(result.score)/\(result.total)")
                        .font(Theme.display(34))
                        .foregroundStyle(Theme.jade)
                        .monospacedDigit()
                    Text("right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.inkSecondary)
                }
            }
            Text(result.score == result.total ? "Perfect minute!" : "Minute complete")
                .font(Theme.display(28))
                .foregroundStyle(Theme.ink)
            Text("Mahj Minute \(result.shortDate)")
                .font(.subheadline)
                .foregroundStyle(Theme.inkSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .themedCard()
    }

    private var breakdown: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("BY SKILL")
                .font(.caption.weight(.heavy))
                .kerning(1.4)
                .foregroundStyle(Theme.inkSecondary)
            ForEach(MahjMinuteCategory.allCases) { category in
                HStack(spacing: 12) {
                    Image(systemName: category.icon)
                        .foregroundStyle(color(for: category))
                        .frame(width: 30)
                    Text(category.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Text("\(result.correct(in: category))/\(result.total(in: category))")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(color(for: category))
                        .monospacedDigit()
                }
            }
        }
        .padding(16)
        .themedCard(corner: 16)
    }

    private func color(for category: MahjMinuteCategory) -> Color {
        let correct = result.correct(in: category)
        let total = result.total(in: category)
        if correct == total { return Theme.jade }
        if correct > 0 { return Theme.gold }
        return Theme.coral
    }
}
