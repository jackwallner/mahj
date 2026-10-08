import Foundation

// Exports the iOS content and generator fixtures for the Android port.
// Run through scripts/sync-android-content.sh, never by hand.
//
//   content.json  every authored drill, the primer, the reference and the
//                 What's New notes, read by the app at runtime.
//   parity.json   seeded generator output, read only by the Android unit
//                 tests to prove the Kotlin generators deal the same tiles.

func code(_ tile: Tile) -> String { tile.shortLabel }
func codes(_ tiles: [Tile]) -> [String] { tiles.map(code) }

// Dictionary iteration can change the final floating-point bit between runs.
// Keep exported scores stable below the parity tests' numerical tolerance.
func fixtureScore(_ value: Double) -> Double { (value * 1_000_000_000).rounded() / 1_000_000_000 }

func flashcard(_ card: Flashcard) -> [String: Any] {
    var json: [String: Any] = [
        "id": card.id,
        "frontTitle": card.frontTitle,
        "frontTiles": codes(card.frontTiles),
        "backTitle": card.backTitle,
        "backBody": card.backBody,
    ]
    if let subtitle = card.frontSubtitle { json["frontSubtitle"] = subtitle }
    if let choice = card.choice {
        json["choice"] = ["options": choice.options, "answerIndex": choice.answerIndex]
    }
    return json
}

func quiz(_ question: QuizQuestion) -> [String: Any] {
    [
        "id": question.id,
        "prompt": question.prompt,
        "tiles": codes(question.tiles),
        "choices": question.choices,
        "answerIndex": question.answerIndex,
        "explanation": question.explanation,
    ]
}

func handMatch(_ question: HandMatchQuestion) -> [String: Any] {
    [
        "id": question.id,
        "tiles": codes(question.tiles),
        "choices": question.choices.map(\.rawValue),
        "answer": question.answer.rawValue,
        "explanation": question.explanation,
    ]
}

func charleston(_ scenario: CharlestonScenario) -> [String: Any] {
    [
        "id": scenario.id,
        "situation": scenario.situation,
        "deal": codes(scenario.deal),
        "recommendedPass": codes(scenario.recommendedPass),
        "reasoning": scenario.reasoning,
        "tip": scenario.tip,
    ]
}

func drill(_ drill: Drill) -> [String: Any] {
    var json: [String: Any] = [
        "id": drill.id,
        "title": drill.title,
        "subtitle": drill.subtitle,
        "isPlus": drill.isPlus,
    ]
    switch drill.kind {
    case .flashcards(let cards): json["kind"] = "flashcards"; json["items"] = cards.map(flashcard)
    case .quiz(let questions): json["kind"] = "quiz"; json["items"] = questions.map(quiz)
    case .handMatch(let questions): json["kind"] = "handMatch"; json["items"] = questions.map(handMatch)
    case .charleston(let scenarios): json["kind"] = "charleston"; json["items"] = scenarios.map(charleston)
    }
    return json
}

func content() -> [String: Any] {
    let rooms: [[String: Any]] = DrillLibrary.rooms.map { room in
        [
            "id": room.id,
            "name": room.name,
            "tagline": room.tagline,
            "icon": room.icon,
            "isFree": room.isFree,
            "drills": room.drills.map(drill),
        ]
    }
    let categories: [[String: Any]] = HandCategory.allCases.map { category in
        [
            "id": category.rawValue,
            "displayName": category.displayName,
            "shortName": category.shortName,
            "howToSpot": category.howToSpot,
            "requires": category.requires,
        ]
    }
    let primer: [[String: Any]] = HowToPlayContent.pages.map { page in
        var json: [String: Any] = [
            "id": page.id, "icon": page.icon, "title": page.title, "body": page.body, "tiles": codes(page.tiles),
        ]
        if let tip = page.tip { json["tip"] = tip }
        return json
    }
    let sections: [[String: Any]] = ReferenceContent.sections.map { section in
        ["category": section.category.rawValue, "exampleRack": codes(section.exampleRack), "watchOut": section.watchOut]
    }
    let glossary: [[String: Any]] = ReferenceContent.glossary.map { term in
        ["id": term.id, "term": term.term, "aliases": term.aliases, "group": term.group.rawValue, "definition": term.definition]
    }
    let whatsNew: [[String: Any]] = WhatsNew.releases.map { release in
        [
            "version": release.version,
            "headline": release.headline,
            "items": release.items.map { item in
                ["id": item.id, "icon": item.icon, "title": item.title, "body": item.body, "isPlus": item.isPlus]
            },
        ]
    }
    return [
        "rooms": rooms,
        "categories": categories,
        "primer": primer,
        "referenceSections": sections,
        "glossary": glossary,
        "whatsNew": whatsNew,
    ]
}

// MARK: - Parity fixtures

func quickItem(_ item: QuickItem) -> [String: Any] {
    [
        "id": item.id,
        "prompt": item.prompt,
        "tiles": codes(item.tiles),
        "choices": item.choices,
        "answerIndex": item.answerIndex,
        "explanation": item.explanation,
        "sourceLabel": item.sourceLabel,
        "roomID": item.roomID,
        "trackingID": item.trackingID,
        "isReviewable": item.isReviewable,
        "choiceNotes": item.choiceNotes.map { $0 ?? NSNull() as Any },
    ]
}

func parity() -> [String: Any] {
    let seeds = ["alpha", "mahj-minute-2026-09-30-racks", "tile-quiz-3", "", "Soap"]
    var streams: [String: [String]] = [:]
    for seed in seeds {
        var generator = StableSeededGenerator(seed: seed)
        streams[seed] = (0..<8).map { _ in String(generator.next()) }
    }
    var permutations: [String: [Int]] = [:]
    for seed in seeds {
        for count in [2, 3, 4, 7, 13] {
            permutations["\(seed)|\(count)"] = ChoiceShuffle.permutation(count: count, seed: seed)
        }
    }

    var racks: [String: Any] = [:]
    var passes: [String: Any] = [:]
    var defenses: [String: Any] = [:]
    for seed in ["r1", "r2", "daily-2026-10-01"] {
        racks[seed] = RackGenerator.batch(count: 7, seed: seed).map { rack in
            [
                "tiles": codes(rack.tiles),
                "answer": rack.answer.rawValue,
                "choices": rack.choices.map(\.rawValue),
                "explanation": rack.explanation,
            ] as [String: Any]
        }
        passes[seed] = CharlestonGenerator.batch(count: 7, seed: seed).map { pass in
            [
                "tiles": codes(pass.tiles),
                "section": pass.section.rawValue,
                "answer": code(pass.answer),
                "choices": codes(pass.choices),
                "explanation": pass.explanation,
                "choiceNotes": pass.choiceNotes.map { $0 ?? NSNull() as Any },
            ] as [String: Any]
        }
        defenses[seed] = DefenseGenerator.batch(count: 7, seed: seed).map { question in
            [
                "exposures": question.exposures.map(codes),
                "section": question.impliedSection.rawValue,
                "answer": code(question.answer),
                "choices": codes(question.choices),
                "explanation": question.explanation,
                "choiceNotes": question.choiceNotes.map { $0 ?? NSNull() as Any },
            ] as [String: Any]
        }
    }

    var deals: [String: Any] = [:]
    var handPlay: [[String: Any]] = []
    for seed in ["deal-1", "deal-2", "deal-3"] {
        let deal = HandPlayEngine.deal(seed: seed)
        deals[seed] = ["rack": codes(deal.rack), "wall": codes(deal.wall)]
        for target in HandPlayEngine.playableTargets {
            let best = HandPlayEngine.bestDiscards(from: deal.rack, target: target)
            let discard = deal.rack[5]
            let wasBest = best.contains(discard)
            handPlay.append([
                "seed": seed,
                "target": target.rawValue,
                "value": fixtureScore(HandPlayEngine.value(of: deal.rack, target: target)),
                "best": codes(best.sorted { $0.sortKey < $1.sortKey }),
                "discard": code(discard),
                "cost": fixtureScore(HandPlayEngine.cost(of: discard, from: deal.rack, target: target)),
                "note": HandPlayEngine.coachNote(for: discard, rack: deal.rack, target: target, wasBest: wasBest),
                "fitting": HandPlayEngine.fittingTiles(in: deal.rack, target: target),
                "working": HandPlayEngine.workingTiles(in: deal.rack, target: target),
            ])
        }
    }
    var verdicts: [[String: Any]] = []
    let verdictDeal = HandPlayEngine.deal(seed: "verdict")
    for (clean, total) in [(0, 12), (6, 12), (9, 12), (12, 12), (0, 0)] {
        for target in HandPlayEngine.playableTargets {
            let verdict = HandPlayEngine.verdict(rack: verdictDeal.rack, target: target, cleanDiscards: clean, discards: total)
            verdicts.append([
                "target": target.rawValue, "clean": clean, "discards": total,
                "stars": verdict.stars, "headline": verdict.headline, "body": verdict.body,
            ])
        }
    }

    var utc = Calendar(identifier: .gregorian)
    utc.timeZone = TimeZone(identifier: "UTC")!
    var minutes: [String: Any] = [:]
    for day in ["2026-09-30", "2026-10-01", "2027-01-15", "2026-02-28"] {
        let parts = day.split(separator: "-").map { Int($0)! }
        let date = utc.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2], hour: 12))!
        let challenge = MahjMinuteContent.challenge(for: date, calendar: utc)
        minutes[day] = [
            "shortDate": challenge.shortDate,
            "questions": challenge.questions.map { ["category": $0.category.rawValue, "item": quickItem($0.item)] },
        ]
    }

    let prepared = SessionBuilder.choiceItems(in: "tile-room", includePro: true)
        + SessionBuilder.choiceItems(in: "card-room", includePro: true)
        + SessionBuilder.choiceItems(in: "charleston-room", includePro: true)
        + SessionBuilder.choiceItems(in: "table-room", includePro: true)
        + SessionBuilder.choiceItems(in: "pro-tables", includePro: true)

    return [
        "streams": streams,
        "permutations": permutations,
        "racks": racks,
        "passes": passes,
        "defenses": defenses,
        "deals": deals,
        "handPlay": handPlay,
        "verdicts": verdicts,
        "minutes": minutes,
        "choicePool": prepared.map { quickItem(SessionBuilder.prepared($0)) },
        "freeReviewable": SessionBuilder.reviewableIDs(includePro: false).sorted(),
        "memberReviewable": SessionBuilder.reviewableIDs(includePro: true).sorted(),
    ]
}

func write(_ object: Any, to path: String) throws {
    let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
    try data.write(to: URL(fileURLWithPath: path))
}

let arguments = CommandLine.arguments
guard arguments.count == 3 else {
    FileHandle.standardError.write("usage: export <content.json> <parity.json>\n".data(using: .utf8)!)
    exit(2)
}
try write(content(), to: arguments[1])
try write(parity(), to: arguments[2])
