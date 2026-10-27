import Foundation

/// Authored teaching content is written in English in `Shared/Content` and
/// translated in `Content.xcstrings`, keyed by the English sentence. The
/// models look their text up here when they are built, so the Swift source
/// stays the single English original that the tests, the Android export and
/// the parity fixture read. A string with no entry (an id, a number, text a
/// generator already localized) comes back unchanged.
enum ContentText {
    static func localized(_ english: String) -> String {
        Bundle.main.localizedString(forKey: english, value: english, table: "Content")
    }

    static func localized(_ english: String?) -> String? {
        english.map { localized($0) }
    }

    static func localized(_ english: [String]) -> [String] {
        english.map { localized($0) }
    }
}

/// Joins phrases the way the English copy always has ("a, b and c"), with the
/// joiners translated. `ListFormatter` would add an Oxford comma in English
/// and change text the Android parity fixture pins.
enum PhraseList {
    static func and(_ items: [String]) -> String {
        guard let last = items.last else { return "" }
        guard items.count > 1 else { return last }
        let head = items.dropLast().joined(separator: String(localized: ", ", comment: "List separator between items, before the final 'and'"))
        return String(localized: "\(head) and \(last)", comment: "The last two items of a list")
    }

    /// "a and b and c": every item joined by "and", as the defense copy reads.
    static func chained(_ items: [String]) -> String {
        guard var result = items.first else { return "" }
        for item in items.dropFirst() {
            result = String(localized: "\(result) and \(item)", comment: "The last two items of a list")
        }
        return result
    }
}
