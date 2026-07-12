import SwiftUI

struct CharlestonDrillView: View {
    let drill: Drill
    let scenarios: [CharlestonScenario]

    @State private var index = 0
    @State private var selected: Set<Int> = []
    @State private var submitted = false
    @State private var score = 0
    @State private var finished = false

    var body: some View {
        if finished {
            DrillCompleteView(drill: drill, score: score, total: scenarios.count * 3)
        } else {
            drillBody
        }
    }

    private var scenario: CharlestonScenario { scenarios[index] }
    /// Deal is shown racked; map display order back to nothing — we grade by tile multiset.
    private var rackedDeal: [Tile] { scenario.deal.racked }

    private var drillBody: some View {
        VStack(spacing: 16) {
            ProgressView(value: Double(index), total: Double(scenarios.count))
                .tint(Theme.felt)
            ScrollView {
                VStack(spacing: 18) {
                    Text(scenario.situation)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                    TileRackView(
                        tiles: rackedDeal,
                        tileWidth: 44,
                        highlightedIndices: selected,
                        onTap: { index in toggle(index) }
                    )
                    .padding(.vertical, 6)
                    if submitted {
                        coachCard
                    } else {
                        Text("Selected \(selected.count) of 3")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            footer
        }
        .padding()
        .background(Theme.background)
        .navigationTitle(drill.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var coachCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: matchCount == 3 ? "star.fill" : "graduationcap.fill")
                    .foregroundStyle(Theme.gold)
                Text(headline)
                    .font(.headline)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Coach would pass:")
                    .font(.subheadline.weight(.semibold))
                HStack(spacing: 6) {
                    ForEach(Array(scenario.recommendedPass.enumerated()), id: \.offset) { _, tile in
                        TileView(tile: tile, width: 40)
                    }
                }
            }
            Text(scenario.reasoning)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(Theme.gold)
                Text(scenario.tip)
                    .font(.footnote.weight(.medium))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 16))
    }

    private var headline: String {
        switch matchCount {
        case 3: return "Perfect pass! 3 of 3"
        case 2: return "Close! 2 of 3 match"
        case 1: return "1 of 3 matched the coach"
        default: return "The coach saw it differently"
        }
    }

    /// Grade by tile multiset so equivalent duplicates count as matches.
    private var matchCount: Int {
        var pool = scenario.recommendedPass
        var matches = 0
        for i in selected {
            if let hit = pool.firstIndex(of: rackedDeal[i]) {
                pool.remove(at: hit)
                matches += 1
            }
        }
        return matches
    }

    private var footer: some View {
        Group {
            if submitted {
                Button {
                    advance()
                } label: {
                    Text(index + 1 < scenarios.count ? "Next Deal" : "Finish").primaryCTA()
                }
            } else {
                Button {
                    submit()
                } label: {
                    Text("Pass These 3").primaryCTA()
                }
                .disabled(selected.count != 3)
                .opacity(selected.count == 3 ? 1 : 0.4)
            }
        }
    }

    private func toggle(_ tileIndex: Int) {
        guard !submitted else { return }
        if selected.contains(tileIndex) {
            selected.remove(tileIndex)
        } else if selected.count < 3 {
            // Jokers may never be passed — enforce the real rule in the drill.
            if case .joker = rackedDeal[tileIndex] { return }
            selected.insert(tileIndex)
        }
    }

    private func submit() {
        guard selected.count == 3 else { return }
        submitted = true
        score += matchCount
    }

    private func advance() {
        if index + 1 < scenarios.count {
            selected = []
            submitted = false
            index += 1
        } else {
            finished = true
        }
    }
}
