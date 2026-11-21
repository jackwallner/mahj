import Foundation

/// Reads a saved `[String: Value]` one entry at a time.
///
/// The stores keep their history as one blob. Decoding it whole means a
/// single damaged entry, or a field a later update makes required, fails the
/// lot: the store starts empty and the next answer saves one record over the
/// history. Here a bad entry is skipped and the rest load. Whenever anything
/// could not be read, the original blob is kept once under `<key>.unreadable`
/// so it can still be recovered.
enum StoredDictionary {
    static func backupKey(for key: String) -> String { key + ".unreadable" }

    /// The readable entries, or nil when nothing is saved under `key`.
    static func load<Value: Decodable>(
        _ type: Value.Type, defaults: UserDefaults, key: String
    ) -> [String: Value]? {
        guard let data = defaults.data(forKey: key) else { return nil }
        guard let saved = try? JSONDecoder().decode([String: Entry<Value>].self, from: data) else {
            keepUnreadable(data, defaults: defaults, key: key)
            return [:]
        }
        let entries = saved.compactMapValues(\.value)
        if entries.count < saved.count { keepUnreadable(data, defaults: defaults, key: key) }
        return entries
    }

    /// One entry that is allowed to fail on its own.
    private struct Entry<Value: Decodable>: Decodable {
        let value: Value?
        init(from decoder: Decoder) throws {
            value = try? Value(from: decoder)
        }
    }

    /// The first unreadable blob wins: a later one may already have lost
    /// what the first still holds.
    private static func keepUnreadable(_ data: Data, defaults: UserDefaults, key: String) {
        let backup = backupKey(for: key)
        guard defaults.data(forKey: backup) == nil else { return }
        defaults.set(data, forKey: backup)
    }
}
