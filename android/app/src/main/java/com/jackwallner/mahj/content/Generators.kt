package com.jackwallner.mahj.content

import com.jackwallner.mahj.model.Dragon
import com.jackwallner.mahj.model.HandCategory
import com.jackwallner.mahj.model.RandomSource
import com.jackwallner.mahj.model.StableSeededGenerator
import com.jackwallner.mahj.model.SystemRandomSource
import com.jackwallner.mahj.model.Tile
import com.jackwallner.mahj.model.nextInt
import com.jackwallner.mahj.model.racked
import com.jackwallner.mahj.model.randomElement
import com.jackwallner.mahj.model.shuffleSwift
import com.jackwallner.mahj.model.Wind

// Ports of the iOS generators. Each one draws from its RandomSource in the
// same order as the Swift original, so seeded output matches iOS tile for
// tile; `GeneratorParityTest` holds them to that.
//
// Legal note, as on iOS: every generator works from the SHAPE of a stable card
// section and never reproduces a hand from the NMJL card.

private val honorTiles: List<Tile> =
    Wind.entries.map { Tile.WindTile(it) } + Dragon.entries.map { Tile.DragonTile(it) }

private fun suitedRanks(tiles: List<Tile>): Set<Int> = tiles.mapNotNull { (it as? Tile.Suited)?.rank }.toSet()

object RackGenerator {
    /** Like Numbers and Quints stay hand-authored: they are never unambiguous. */
    val generatableCategories = listOf(
        HandCategory.EVENS_2468,
        HandCategory.ODDS_13579,
        HandCategory.THREE_SIX_NINE,
        HandCategory.CONSECUTIVE_RUN,
        HandCategory.WINDS_DRAGONS,
    )

    /** Written to be mutually exclusive across `generatableCategories`. */
    fun fits(tiles: List<Tile>, category: HandCategory): Boolean {
        val ranks = suitedRanks(tiles)
        val honors = tiles.any { it.isHonor }
        return when (category) {
            HandCategory.WINDS_DRAGONS -> honors && tiles.none { it is Tile.Suited }
            HandCategory.EVENS_2468 -> !honors && ranks.isNotEmpty() && setOf(2, 4, 6, 8).containsAll(ranks) && ranks.size >= 2
            HandCategory.ODDS_13579 -> !honors && ranks.isNotEmpty() && setOf(1, 3, 5, 7, 9).containsAll(ranks) && ranks.size >= 2
            HandCategory.THREE_SIX_NINE -> !honors && setOf(3, 6, 9).containsAll(ranks) && 6 in ranks && (3 in ranks || 9 in ranks)
            HandCategory.CONSECUTIVE_RUN -> {
                if (honors || ranks.size < 3) return false
                ranks.max() - ranks.min() == ranks.size - 1
            }
            else -> false
        }
    }

    /** The one section a rack reads as, or null if it reads as none or several. */
    fun category(tiles: List<Tile>): HandCategory? =
        generatableCategories.filter { fits(tiles, it) }.singleOrNull()

    data class GeneratedRack(
        val tiles: List<Tile>,
        val answer: HandCategory,
        val choices: List<HandCategory>,
        val explanation: String,
    )

    private val groupPartitions = listOf(
        listOf(4, 3, 3, 3),
        listOf(3, 3, 3, 2, 2),
        listOf(4, 4, 3, 2),
        listOf(2, 2, 3, 3, 3),
        listOf(4, 4, 2, 3),
        listOf(3, 2, 2, 3, 3),
        listOf(4, 2, 2, 2, 3),
    )

    internal fun palette(category: HandCategory, source: RandomSource): List<Tile> = when (category) {
        HandCategory.EVENS_2468 -> Tile.suited(listOf(2, 4, 6, 8))
        HandCategory.ODDS_13579 -> Tile.suited(listOf(1, 3, 5, 7, 9))
        HandCategory.THREE_SIX_NINE -> Tile.suited(listOf(3, 6, 9))
        HandCategory.CONSECUTIVE_RUN -> {
            val start = source.nextInt(1..6)
            Tile.suited((start..start + 3).toList())
        }
        HandCategory.WINDS_DRAGONS -> honorTiles
        else -> emptyList()
    }

    private fun deal(category: HandCategory, source: RandomSource): List<Tile>? {
        val available = palette(category, source).toMutableList()
        available.shuffleSwift(source)
        val partition = groupPartitions.randomElement(source) ?: return null
        if (available.size < partition.size) return null
        val tiles = mutableListOf<Tile>()
        for (size in partition) {
            if (available.isEmpty()) return null
            val tile = available.removeAt(0)
            repeat(size) { tiles += tile }
        }
        if (tiles.size != 13) return null
        return tiles.racked
    }

    private fun rack(target: HandCategory, attempts: Int, source: RandomSource): GeneratedRack? {
        repeat(attempts) {
            val tiles = deal(target, source) ?: return@repeat
            if (category(tiles) != target) return@repeat
            val distractors = generatableCategories.filter { it != target && !fits(tiles, it) }.toMutableList()
            distractors.shuffleSwift(source)
            val picked = distractors.take(3)
            if (picked.size < 2) return@repeat
            val choices = (listOf(target) + picked).toMutableList()
            choices.shuffleSwift(source)
            return GeneratedRack(tiles, target, choices, explain(tiles, target))
        }
        return null
    }

    fun rack(target: HandCategory, attempts: Int = 200): GeneratedRack? = rack(target, attempts, SystemRandomSource)

    fun batch(count: Int): List<GeneratedRack> = batch(count, SystemRandomSource)

    /** Reproducible for a dated shared challenge. */
    fun batch(count: Int, seed: String): List<GeneratedRack> = batch(count, StableSeededGenerator(seed))

    private fun batch(count: Int, source: RandomSource): List<GeneratedRack> {
        val targets = mutableListOf<HandCategory>()
        while (targets.size < count) {
            val pass = generatableCategories.toMutableList()
            pass.shuffleSwift(source)
            targets += pass
        }
        val racks = targets.take(count).mapNotNull { rack(it, 200, source) }.toMutableList()
        racks.shuffleSwift(source)
        return racks
    }

    fun explain(tiles: List<Tile>, answer: HandCategory): String {
        val list = suitedRanks(tiles).sorted().joinToString(", ")
        return when (answer) {
            HandCategory.EVENS_2468 -> "Every number on this rack is even ($list), with no honors at all. That is 2468 territory, and every odd tile you pick up is dead weight for it."
            HandCategory.ODDS_13579 -> "Every number here is odd ($list). That points straight at 13579, the mirror image of the evens section."
            HandCategory.THREE_SIX_NINE -> "The rack holds only 3s, 6s and 9s ($list). The 6 rules out a pure odds hand and the 3 or 9 rules out a pure evens hand, so 369 is the read."
            HandCategory.CONSECUTIVE_RUN -> "The numbers step up in order ($list). A run mixes odd and even by definition, so it cannot be an evens or odds hand: this is a Consecutive Run."
            HandCategory.WINDS_DRAGONS -> "Nothing but winds and dragons, with no numbered tiles anywhere. When honors pile up like this, Winds and Dragons is where to look."
            else -> HandCategory.YEAR.howToSpot
        }
    }
}

/** Original Charleston decisions: a rack with a clear direction and one tile that fits nothing. */
object CharlestonGenerator {
    data class GeneratedPass(
        val tiles: List<Tile>,
        val section: HandCategory,
        val answer: Tile,
        val choices: List<Tile>,
        val explanation: String,
        val choiceNotes: List<String?>,
    )

    private val corePartitions = listOf(
        listOf(4, 4, 4),
        listOf(3, 3, 3, 3),
        listOf(4, 3, 3, 2),
        listOf(3, 4, 3, 2),
    )

    fun pass(attempts: Int = 200): GeneratedPass? = pass(attempts, SystemRandomSource)

    fun batch(count: Int): List<GeneratedPass> = (0 until count).mapNotNull { pass(200, SystemRandomSource) }

    fun batch(count: Int, seed: String): List<GeneratedPass> {
        val source = StableSeededGenerator(seed)
        return (0 until count).mapNotNull { pass(200, source) }
    }

    private fun pass(attempts: Int, source: RandomSource): GeneratedPass? {
        repeat(attempts) {
            val section = RackGenerator.generatableCategories.randomElement(source) ?: return@repeat
            build(section, source)?.let { return it }
        }
        return null
    }

    private fun build(section: HandCategory, source: RandomSource): GeneratedPass? {
        val palette = RackGenerator.palette(section, source).toMutableList()
        palette.shuffleSwift(source)
        val partition = corePartitions.randomElement(source) ?: return null
        if (palette.size < partition.size) return null

        val core = mutableListOf<Tile>()
        val groupLeaders = mutableListOf<Tile>()
        for (size in partition) {
            if (palette.isEmpty()) return null
            val tile = palette.removeAt(0)
            repeat(size) { core += tile }
            if (size >= 3) groupLeaders += tile
        }
        if (core.size != 12 || groupLeaders.size < 3) return null

        val strays = outsiders(section, 1, source) ?: return null
        val rack = (core + strays).racked
        if (rack.size != 13) return null

        val answer = strays[0]
        groupLeaders.shuffleSwift(source)
        val distractors = groupLeaders.take(3)
        if (distractors.size != 3) return null

        val choices = (listOf(answer) + distractors).toMutableList()
        choices.shuffleSwift(source)

        val notes = choices.map { tile ->
            if (tile == answer) null else {
                val held = rack.count { it == tile }
                "You are holding $held of the ${tile.spokenName}. Passing one breaks a group you have already built, and you would have to rebuild it from a suit somebody else may be collecting."
            }
        }
        return GeneratedPass(rack, section, answer, choices, explain(rack, section, answer), notes)
    }

    /** Flowers and jokers are never strays. */
    private fun outsiders(section: HandCategory, count: Int, source: RandomSource): List<Tile>? {
        val pool = if (section == HandCategory.WINDS_DRAGONS) {
            Tile.allSuited.toMutableList()
        } else {
            val fitting = inPaletteRanks(section).toSet()
            (Tile.allSuited.filter { (it as Tile.Suited).rank !in fitting } + honorTiles).toMutableList()
        }
        pool.shuffleSwift(source)
        val picked = mutableListOf<Tile>()
        for (tile in pool) {
            if (tile in picked) continue
            picked += tile
            if (picked.size == count) return picked
        }
        return null
    }

    private fun inPaletteRanks(section: HandCategory): List<Int> = when (section) {
        HandCategory.EVENS_2468 -> listOf(2, 4, 6, 8)
        HandCategory.ODDS_13579 -> listOf(1, 3, 5, 7, 9)
        HandCategory.THREE_SIX_NINE -> listOf(3, 6, 9)
        HandCategory.CONSECUTIVE_RUN -> (1..9).toList()
        else -> emptyList()
    }

    fun explain(rack: List<Tile>, section: HandCategory, answer: Tile): String {
        val copies = rack.count { it == answer }
        val loneness = if (copies == 1) "You hold exactly one of it"
        else "You hold $copies of it and nothing else that pairs with them"
        return "This rack is pointed at ${section.displayName}: ${section.requires}. The ${answer.spokenName} fits none of that. $loneness, so it is the tile you can lose for free, and the first pass is where junk should go. Every other tile here is already part of a group you have built."
    }
}

/** Original defensive-discard questions: one opponent's exposures point somewhere obvious. */
object DefenseGenerator {
    data class GeneratedDefense(
        val exposures: List<List<Tile>>,
        val impliedSection: HandCategory,
        val answer: Tile,
        val choices: List<Tile>,
        val explanation: String,
        val choiceNotes: List<String?>,
    )

    val readableSections = listOf(HandCategory.EVENS_2468, HandCategory.ODDS_13579, HandCategory.THREE_SIX_NINE)

    fun question(): GeneratedDefense? = question(60, SystemRandomSource)

    fun batch(count: Int): List<GeneratedDefense> = (0 until count).mapNotNull { question(60, SystemRandomSource) }

    fun batch(count: Int, seed: String): List<GeneratedDefense> {
        val source = StableSeededGenerator(seed)
        return (0 until count).mapNotNull { question(60, source) }
    }

    private fun question(attempts: Int, source: RandomSource): GeneratedDefense? {
        repeat(attempts) {
            val section = readableSections.randomElement(source) ?: return@repeat
            build(section, source)?.let { return it }
        }
        return null
    }

    private fun build(section: HandCategory, source: RandomSource): GeneratedDefense? {
        val dangerous = dangerousTiles(section).toMutableList()
        dangerous.shuffleSwift(source)
        if (dangerous.size < 5) return null

        val exposed = dangerous.take(2)
        val first = (exposed[0] as? Tile.Suited)?.rank
        val second = (exposed[1] as? Tile.Suited)?.rank
        if (first != null && second != null && first == second) return null
        val bait = dangerous.drop(2).take(3)
        val exposures = exposed.map { tile -> List(3) { tile } }

        val safe = safeTile(section, exposed, exposed + bait, source) ?: return null
        val choices = (bait + safe).toMutableList()
        choices.shuffleSwift(source)

        val notes = choices.map { tile ->
            if (tile == safe) null
            else "The ${tile.spokenName} sits squarely inside ${section.displayName}, which is where those exposures point. Late in a hand that is the discard that ends it."
        }
        return GeneratedDefense(exposures, section, safe, choices, explain(exposures, section, safe), notes)
    }

    private fun dangerousTiles(section: HandCategory): List<Tile> = when (section) {
        HandCategory.EVENS_2468 -> Tile.suited(listOf(2, 4, 6, 8))
        HandCategory.ODDS_13579 -> Tile.suited(listOf(1, 3, 5, 7, 9))
        HandCategory.THREE_SIX_NINE -> Tile.suited(listOf(3, 6, 9))
        else -> emptyList()
    }

    private fun safeTile(section: HandCategory, exposed: List<Tile>, used: List<Tile>, source: RandomSource): Tile? {
        val exposedRanks = exposed.mapNotNull { (it as? Tile.Suited)?.rank }
        val low = exposedRanks.minOrNull() ?: return null
        val high = exposedRanks.max()
        val sameParity = exposedRanks.all { it % 2 == low % 2 }

        val safeRanks = (1..9).filter { candidate ->
            val outsideSection = when (section) {
                HandCategory.EVENS_2468 -> candidate % 2 != 0
                HandCategory.ODDS_13579 -> candidate % 2 == 0
                HandCategory.THREE_SIX_NINE -> candidate % 3 != 0
                else -> return@filter false
            }
            val outsideRun = maxOf(high, candidate) - minOf(low, candidate) > 4
            val outsideParity = !sameParity || (candidate % 2 == 0) != (low % 2 == 0)
            outsideSection && outsideRun && outsideParity
        }
        val pool = Tile.suited(safeRanks).filter { it !in used }.toMutableList()
        pool.shuffleSwift(source)
        return pool.firstOrNull()
    }

    fun explain(exposures: List<List<Tile>>, section: HandCategory, safe: Tile): String {
        val shown = exposures.mapNotNull { it.firstOrNull() }.joinToString(" and a pung of ") { it.spokenName }
        return "A pung of $shown both sit inside ${section.displayName}, so that is the family this player is building. The ${safe.spokenName} cannot belong to it: ${section.requires}. Throw the tile their exposures rule out, and keep the ones they are clearly still collecting."
    }
}
