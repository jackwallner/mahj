import SwiftUI

/// The at-the-table reference: search a term, or read a section. Free for
/// everyone and reachable in one tap from Home, because the moment it is
/// actually needed is mid-game with a rack in front of you, not during a
/// practice session.
struct ReferenceView: View {
    @State private var query = ""
    @State private var tab: Tab = .glossary
    @State private var expandedSection: HandCategory?

    enum Tab: String, CaseIterable, Identifiable {
        case glossary, sections
        var id: String { rawValue }
        var title: String {
            switch self {
            case .glossary: return "Glossary"
            case .sections: return "Sections"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("View", selection: $tab) {
                ForEach(Tab.allCases) { tab in
                    Text(tab.title).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom, 10)

            ScrollView {
                VStack(spacing: 12) {
                    switch tab {
                    case .glossary: glossaryList
                    case .sections: sectionList
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 28)
                .frame(maxWidth: Theme.readableContentWidth)
                .frame(maxWidth: .infinity)
            }
        }
        .background(Theme.background)
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always),
                    prompt: tab == .glossary ? "Search terms" : "Search sections")
        .navigationTitle("Reference")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Glossary

    private var glossaryList: some View {
        let groups = GlossaryGroup.allCases.compactMap { group -> (GlossaryGroup, [GlossaryTerm])? in
            let terms = ReferenceContent.terms(in: group, matching: query)
            return terms.isEmpty ? nil : (group, terms)
        }
        return Group {
            if groups.isEmpty {
                emptyState(
                    icon: "magnifyingglass",
                    title: "Nothing matches \"\(query)\"",
                    body: "Try a shorter word. Nicknames work too: soap, news, wild."
                )
            } else {
                ForEach(groups, id: \.0.id) { group, terms in
                    VStack(alignment: .leading, spacing: 8) {
                        groupHeading(group)
                        VStack(spacing: 0) {
                            ForEach(Array(terms.enumerated()), id: \.element.id) { index, term in
                                termRow(term)
                                if index < terms.count - 1 {
                                    Divider().background(Theme.rule).padding(.leading, 14)
                                }
                            }
                        }
                        .themedCard(corner: 16)
                    }
                }
            }
        }
    }

    private func groupHeading(_ group: GlossaryGroup) -> some View {
        HStack(spacing: 6) {
            Image(systemName: group.icon)
                .font(.caption)
                .foregroundStyle(Theme.jade)
            Text(group.title.uppercased())
                .font(.caption.weight(.heavy))
                .kerning(1.3)
                .foregroundStyle(Theme.inkSecondary)
            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.top, 6)
    }

    private func termRow(_ term: GlossaryTerm) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(term.term)
                .font(.headline)
                .foregroundStyle(Theme.ink)
            Text(term.definition)
                .font(.subheadline)
                .foregroundStyle(Theme.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
    }

    // MARK: - Sections

    private var sectionList: some View {
        let matches = ReferenceContent.sections(matching: query)
        return Group {
            if matches.isEmpty {
                emptyState(
                    icon: "menucard",
                    title: "No section matches \"\(query)\"",
                    body: "Sections are families like evens, odds, 369 and consecutive runs."
                )
            } else {
                disclaimer
                ForEach(matches) { reference in
                    sectionCard(reference)
                }
            }
        }
    }

    private var disclaimer: some View {
        Text("Every rack below is an original teaching example for the shape of the section. For the actual hands and their values, use the current NMJL card.")
            .font(.caption)
            .foregroundStyle(Theme.inkTertiary)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Theme.well, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.top, 6)
    }

    private func sectionCard(_ reference: SectionReference) -> some View {
        let expanded = expandedSection == reference.category
        return VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    expandedSection = expanded ? nil : reference.category
                }
            } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(reference.category.displayName)
                            .font(.headline)
                            .foregroundStyle(Theme.ink)
                            .multilineTextAlignment(.leading)
                        Text(reference.category.howToSpot)
                            .font(.subheadline)
                            .foregroundStyle(Theme.inkSecondary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 4)
                    Image(systemName: "chevron.down")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Theme.inkTertiary)
                        .rotationEffect(.degrees(expanded ? 180 : 0))
                }
            }
            .buttonStyle(.plain)

            if expanded {
                VStack(alignment: .leading, spacing: 10) {
                    Text("AN EXAMPLE OF THE SHAPE")
                        .font(.caption2.weight(.heavy))
                        .kerning(1.2)
                        .foregroundStyle(Theme.inkTertiary)
                    TileRackView(tiles: reference.exampleRack.racked, tileWidth: 36)
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(Theme.gold)
                        Text(reference.watchOut)
                            .font(.footnote)
                            .foregroundStyle(Theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .themedCard(corner: 16)
    }

    // MARK: - Empty

    private func emptyState(icon: String, title: String, body: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 34))
                .foregroundStyle(Theme.jade.opacity(0.5))
            Text(title)
                .font(.headline)
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(body)
                .font(.subheadline)
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .themedCard()
        .padding(.top, 16)
    }
}
