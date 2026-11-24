package com.jackwallner.mahj.content

/**
 * How far into the game an item reaches. Sessions use it to keep a new
 * player's questions to what a first lesson covers and to let them in on the
 * rest as they show they have it. Never shown to the player.
 */
enum class Difficulty(val raw: String) {
    /** Tile names, suits, dragons, jokers, the set itself and reading a line of the card. */
    BASIC("basic"),

    /** Groups, calling and exposing, scoring, the sections and reading a rack. */
    INTERMEDIATE("intermediate"),

    /** Rule-of-thumb strategy calls, defense, decoy racks and edge rules. */
    CHALLENGING("challenging");

    companion object {
        fun fromRaw(raw: String): Difficulty = entries.first { it.raw == raw }
    }
}

/**
 * The tier of every drill item, keyed by id. The table itself is Swift's
 * `ItemDifficulty.table`, exported into the content; never copy it here.
 */
object ItemDifficulty {
    val tiers: Map<String, Difficulty> get() = MahjContent.library.itemDifficulty

    fun of(id: String): Difficulty = tiers[id] ?: Difficulty.INTERMEDIATE
}

/** Where a player's sessions top out. The onboarding answer sets the floor; accuracy raises the ceiling. */
object SessionLevel {
    /** Share of a tier answered right (latest answer) that opens the next one. */
    const val PROMOTION_ACCURACY = 0.8

    /** Share of a tier that must have been answered before it can promote. */
    const val PROMOTION_COVERAGE = 0.6

    /** The onboarding answer (`mahj.skillLevel`). Unset is a player from before the question, who keeps the full mix. */
    fun seed(skillLevel: String): Difficulty = when (skillLevel) {
        "new" -> Difficulty.BASIC
        "basics" -> Difficulty.INTERMEDIATE
        else -> Difficulty.CHALLENGING
    }

    /** The ceiling earned from `start` given what the player has answered. It never steps down. */
    fun ceiling(start: Difficulty, seen: Set<String>, missed: Set<String>, includePro: Boolean): Difficulty {
        val pool = SessionBuilder.poolIDs(includePro)
        var level = start
        while (level < Difficulty.CHALLENGING && promotes(level, pool, seen, missed)) {
            level = Difficulty.entries[level.ordinal + 1]
        }
        return level
    }

    fun promotes(tier: Difficulty, pool: List<String>, seen: Set<String>, missed: Set<String>): Boolean {
        val ids = pool.filter { ItemDifficulty.of(it) == tier }
        if (ids.isEmpty()) return true
        val answered = ids.filter { it in seen }
        val needed = maxOf(1, kotlin.math.ceil(ids.size * PROMOTION_COVERAGE).toInt())
        if (answered.size < needed) return false
        val right = answered.count { it !in missed }
        return right.toDouble() / answered.size >= PROMOTION_ACCURACY
    }
}
