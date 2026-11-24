package com.jackwallner.mahj.data

import org.json.JSONObject

/**
 * Reads a saved `{id: entry}` blob one entry at a time (iOS `StoredDictionary`).
 *
 * Parsing it whole meant one damaged entry failed the lot: the store started empty and the next
 * answer saved one record over the history. Here a bad entry is skipped and the rest load. When
 * anything could not be read, the original blob is kept once under `<key>.unreadable`.
 */
object StoredDictionary {
    fun backupKey(key: String) = "$key.unreadable"

    /** The readable entries, or null when nothing is saved under `key`. */
    fun <T> load(defaults: KeyValueStore, key: String, decode: (JSONObject) -> T): Map<String, T>? {
        val raw = defaults.getString(key) ?: return null
        val json = runCatching { JSONObject(raw) }.getOrNull()
        if (json == null) {
            keepUnreadable(defaults, key, raw)
            return emptyMap()
        }
        val names = json.keys().asSequence().toList()
        val entries = names.mapNotNull { name ->
            runCatching { name to decode(json.getJSONObject(name)) }.getOrNull()
        }.toMap()
        if (entries.size < names.size) keepUnreadable(defaults, key, raw)
        return entries
    }

    /** The first unreadable blob wins: a later one may already have lost what the first still holds. */
    private fun keepUnreadable(defaults: KeyValueStore, key: String, raw: String) {
        val backup = backupKey(key)
        if (!defaults.contains(backup)) defaults.putString(backup, raw)
    }
}
