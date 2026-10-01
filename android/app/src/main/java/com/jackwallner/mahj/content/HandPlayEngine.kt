package com.jackwallner.mahj.content

import com.jackwallner.mahj.model.HandCategory
import com.jackwallner.mahj.model.RandomSource
import com.jackwallner.mahj.model.StableSeededGenerator
import com.jackwallner.mahj.model.SystemRandomSource
import com.jackwallner.mahj.model.Tile
import com.jackwallner.mahj.model.racked
import com.jackwallner.mahj.model.shuffleSwift

/**
 * A single-player hand: commit to a section, then draw and discard toward it
 * while a coach grades every throw. No opponents and no bots, on purpose.
 *
 * Legal note, as on iOS: racks are scored against the SHAPE of a family,
 * never against a hand from the NMJL card.
 */
object HandPlayEngine {
    const val TURN_COUNT = 12

    val playableTargets: List<HandCategory> get() = RackGenerator.generatableCategories

    /** All 152 tiles: 108 numbers, 16 winds, 12 dragons, 8 flowers, 8 jokers. */
    val fullSet: List<Tile>
        get() {
            val tiles = mutableListOf<Tile>()
            for (tile in Tile.allSuited) repeat(4) { tiles += tile }
            for (tile in Tile.allHonors) repeat(4) { tiles += tile }
            repeat(8) { tiles += Tile.Flower }
            repeat(8) { tiles += Tile.Joker }
            return tiles
        }

    data class Deal(val rack: List<Tile>, val wall: List<Tile>)

    fun deal(): Deal = deal(SystemRandomSource)

    fun deal(seed: String): Deal = deal(StableSeededGenerator(seed))

    fun deal(source: RandomSource): Deal {
        val tiles = fullSet.toMutableList()
        tiles.shuffleSwift(source)
        return Deal(tiles.take(13).racked, tiles.drop(13))
    }

    /** Flowers count for every playable family; jokers belong everywhere. */
    fun belongs(tile: Tile, target: HandCategory, runRange: IntRange? = null): Boolean = when (tile) {
        Tile.Flower, Tile.Joker -> true
        is Tile.WindTile, is Tile.DragonTile -> target == HandCategory.WINDS_DRAGONS
        is Tile.Suited -> when (target) {
            HandCategory.EVENS_2468 -> tile.rank in listOf(2, 4, 6, 8)
            HandCategory.ODDS_13579 -> tile.rank in listOf(1, 3, 5, 7, 9)
            HandCategory.THREE_SIX_NINE -> tile.rank in listOf(3, 6, 9)
            HandCategory.CONSECUTIVE_RUN -> runRange?.contains(tile.rank) ?: true
            else -> false
        }
    }

    /** The four adjacent numbers a rack's run is centred on. */
    fun bestRunRange(tiles: List<Tile>): IntRange {
        var best = 1..4
        var bestCount = -1
        for (start in 1..6) {
            val range = start..start + 3
            val count = tiles.count { it is Tile.Suited && it.rank in range }
            if (count > bestCount) {
                bestCount = count
                best = range
            }
        }
        return best
    }

    private fun runRangeFor(tiles: List<Tile>, target: HandCategory): IntRange? =
        if (target == HandCategory.CONSECUTIVE_RUN) bestRunRange(tiles) else null

    /** How much of a rack is doing work toward a section, scored by groups. */
    fun value(tiles: List<Tile>, target: HandCategory): Double {
        val range = runRangeFor(tiles, target)
        var total = 0.0
        for ((tile, count) in tiles.groupingBy { it }.eachCount()) {
            if (tile == Tile.Joker) {
                total += 3.2 * count
                continue
            }
            if (!belongs(tile, target, range)) continue
            total += when {
                count >= 4 -> 4.2 * (count / 4) + groupValue(count % 4)
                count == 3 -> 3.2
                count == 2 -> 1.7
                else -> 0.6
            }
        }
        return total
    }

    private fun groupValue(count: Int): Double = when (count) {
        3 -> 3.2
        2 -> 1.7
        1 -> 0.6
        else -> 0.0
    }

    data class RankedTarget(val target: HandCategory, val value: Double)

    fun rankedTargets(tiles: List<Tile>): List<RankedTarget> =
        playableTargets.map { RankedTarget(it, value(tiles, it)) }.sortedByDescending { it.value }

    private fun removingOne(rack: List<Tile>, tile: Tile): List<Tile> =
        rack.toMutableList().also { list -> list.indexOf(tile).takeIf { it >= 0 }?.let { list.removeAt(it) } }

    /** Every tile whose loss costs the least. Ties are all graded correct. */
    fun bestDiscards(rack: List<Tile>, target: HandCategory): Set<Tile> {
        val distinct = rack.toSet()
        if (distinct.isEmpty()) return emptySet()
        val scored = distinct.map { it to value(removingOne(rack, it), target) }
        val best = scored.maxOf { it.second }
        return scored.filter { it.second > best - 0.0001 }.map { it.first }.toSet()
    }

    /** What one throw cost, against the cheapest throw available. */
    fun cost(tile: Tile, rack: List<Tile>, target: HandCategory): Double {
        if (tile !in rack) return 0.0
        val best = rack.toSet().maxOfOrNull { value(removingOne(rack, it), target) } ?: 0.0
        return maxOf(0.0, best - value(removingOne(rack, tile), target))
    }

    fun coachNote(discard: Tile, rack: List<Tile>, target: HandCategory, wasBest: Boolean): String {
        val range = runRangeFor(rack, target)
        val copies = rack.count { it == discard }
        val fits = belongs(discard, target, range)

        if (wasBest) {
            if (discard == Tile.Joker) return "That was the only throw available, but jokers are never junk. Hold them."
            if (!fits) return "Right. The ${discard.spokenName} does nothing for ${target.displayName}, and the tiles that do nothing are the ones to spend first."
            val held = if (copies == 1) "one" else "$copies"
            return "Good throw. It fits ${target.displayName}, but you were holding only $held of it, so it was the cheapest thing on your rack."
        }

        val suggestion = bestDiscards(rack, target).minByOrNull { it.sortKey }
        var note = when {
            discard == Tile.Joker -> "Never throw a joker. It can fill any group of three or more, which makes it the most valuable tile on your rack."
            copies >= 3 -> "You just broke a group. You were holding $copies of the ${discard.spokenName}, and rebuilding that costs you tiles somebody else may already be collecting."
            copies == 2 -> "That was half a pair. A pair is the cheapest route to a pung, so it is worth more than the two loose tiles it looks like."
            fits -> "The ${discard.spokenName} fits ${target.displayName}, so throwing it costs you a tile you would have wanted back."
            else -> "That tile was already outside ${target.displayName}, so the throw was not wrong so much as second best."
        }
        if (suggestion != null) note += " The cheapest throw here was the ${suggestion.spokenName}."
        return note
    }

    data class Verdict(
        val fitting: Int,
        val working: Int,
        val total: Int,
        val cleanDiscards: Int,
        val discards: Int,
        val target: HandCategory,
        val stars: Int,
        val headline: String,
        val body: String,
    )

    /** Tiles that belong to the section and sit in a group of two or more. */
    fun workingTiles(rack: List<Tile>, target: HandCategory): Int {
        val range = runRangeFor(rack, target)
        return rack.groupingBy { it }.eachCount().entries.sumOf { (tile, count) ->
            when {
                tile == Tile.Joker -> count
                belongs(tile, target, range) && count >= 2 -> count
                else -> 0
            }
        }
    }

    /** Tiles that simply belong to the section, paired or not. */
    fun fittingTiles(rack: List<Tile>, target: HandCategory): Int {
        val range = runRangeFor(rack, target)
        return rack.count { belongs(it, target, range) }
    }

    fun verdict(rack: List<Tile>, target: HandCategory, cleanDiscards: Int, discards: Int): Verdict {
        val fitting = fittingTiles(rack, target)
        val working = workingTiles(rack, target)
        val accuracy = if (discards == 0) 0.0 else cleanDiscards.toDouble() / discards
        val shape = fitting.toDouble() / maxOf(rack.size, 1)
        val combined = accuracy * 0.6 + shape * 0.4

        val stars = when {
            combined >= 0.82 -> 3
            combined >= 0.6 -> 2
            combined >= 0.35 -> 1
            else -> 0
        }
        val headline = when (stars) {
            3 -> "That is how you build a hand"
            2 -> "Solid hand"
            1 -> "You got there in the end"
            else -> "That one fought you"
        }
        val grouped = if (working == 0) "None of them have paired up yet, and pairs are what turn a collection into a hand."
        else "$working of them are already sitting in a group of two or more, which is the half that counts."
        val body = "You finished with $fitting of ${rack.size} tiles that fit ${target.displayName}. $grouped $cleanDiscards of your $discards throws were the cheapest one available, and that is the number to chase: the shape you are building toward is the whole game, and everything outside it is what you spend."
        return Verdict(fitting, working, rack.size, cleanDiscards, discards, target, stars, headline, body)
    }
}
