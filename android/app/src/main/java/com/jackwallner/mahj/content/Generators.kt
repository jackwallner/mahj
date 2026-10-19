package com.jackwallner.mahj.content

import com.jackwallner.mahj.model.Dragon
import com.jackwallner.mahj.model.HandCategory
import com.jackwallner.mahj.model.RandomSource
import com.jackwallner.mahj.model.StableSeededGenerator
import com.jackwallner.mahj.model.Suit
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

    /**
     * Shapes that read as a section on paper but invite a second read: more
     * than five of one number reads as Like Numbers, and an odds rack of only
     * 3s and 9s reads as 369 just as well (iOS parity).
     */
    fun isClean(tiles: List<Tile>, section: HandCategory): Boolean {
        val counts = tiles.mapNotNull { (it as? Tile.Suited)?.rank }.groupingBy { it }.eachCount()
        if ((counts.values.maxOrNull() ?: 0) > 5) return false
        if (section == HandCategory.ODDS_13579 && setOf(3, 9).containsAll(counts.keys)) return false
        return true
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
            if (category(tiles) != target || !isClean(tiles, target)) return@repeat
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

    /** Why a wrong section does not fit THIS rack, naming the tiles that rule it out. */
    fun missNotes(tiles: List<Tile>, choices: List<HandCategory>, answer: HandCategory): List<String?> =
        choices.map { if (it == answer) null else missNote(tiles, it, answer) }

    fun missNote(tiles: List<Tile>, choice: HandCategory, answer: HandCategory): String {
        val ranks = suitedRanks(tiles).sorted()
        val generic = "${choice.displayName} could use some of these tiles, but more of them point to ${answer.displayName}."
        val noNumbers = "This rack has no numbered tiles at all, and ${choice.displayName} is built from numbers."
        return when (choice) {
            HandCategory.EVENS_2468 -> {
                val odd = ranks.filter { it % 2 != 0 }
                when {
                    ranks.isEmpty() -> noNumbers
                    odd.isEmpty() -> generic
                    else -> "This rack holds ${plural(odd)}, and a finished 2468 hand never uses an odd number."
                }
            }
            HandCategory.ODDS_13579 -> {
                val even = ranks.filter { it % 2 == 0 }
                when {
                    ranks.isEmpty() -> noNumbers
                    even.isEmpty() -> generic
                    else -> "This rack holds ${plural(even)}, and a finished 13579 hand never uses an even number."
                }
            }
            HandCategory.THREE_SIX_NINE -> {
                val outside = ranks.filter { it % 3 != 0 }
                when {
                    ranks.isEmpty() -> noNumbers
                    outside.isNotEmpty() -> "This rack holds ${plural(outside)}, and a finished 369 hand never uses them."
                    6 in ranks -> generic
                    else -> "There is no 6 here, and 369 needs the 6 to read as anything other than odds."
                }
            }
            HandCategory.CONSECUTIVE_RUN -> when {
                ranks.isEmpty() -> "A run is all numbers stepping up in order, and this rack has no numbered tiles."
                ranks.size < 3 -> "A run steps up with no gaps, and this rack only has ${plural(ranks)}."
                // Any three numbers in a row is the start of a run, so only a rack
                // without one is ruled out by its gaps.
                ranks.none { (it + 1) in ranks && (it + 2) in ranks } -> "The numbers here (${ranks.joinToString(", ")}) never make three in a row, and a run steps up with no gaps."
                else -> generic
            }
            HandCategory.WINDS_DRAGONS -> {
                val suited = tiles.count { it is Tile.Suited }
                val honors = tiles.count { it.isHonor }
                val honorCount = when (honors) {
                    0 -> "no winds or dragons"
                    1 -> "only one wind or dragon"
                    else -> "only $honors winds or dragons"
                }
                if (suited > honors) "This rack has $suited numbered tiles and $honorCount, so it has little to build a Winds & Dragons hand from." else generic
            }
            HandCategory.LIKE_NUMBERS -> when {
                ranks.isEmpty() -> noNumbers
                ranks.size >= 3 -> "Like Numbers repeats one number across the suits, and this rack spreads across ${plural(ranks)}."
                tiles.count { it is Tile.Suited } < 5 -> {
                    val numbered = tiles.count { it is Tile.Suited }
                    "Like Numbers is built from one number in several suits, and this rack has only $numbered number tile${if (numbered == 1) "" else "s"}."
                }
                else -> generic
            }
            // The digits change with every card, so the note never names them.
            HandCategory.YEAR -> if (ranks.isEmpty()) noNumbers else generic
            HandCategory.QUINTS -> {
                val jokers = tiles.count { it == Tile.Joker }
                if (jokers < 2) "Quints need five of a kind, which takes jokers, and this rack has ${if (jokers == 0) "none" else "just one"}." else generic
            }
            HandCategory.SINGLES_AND_PAIRS -> {
                // Flowers are left out: a third flower is just a spare, not a pung.
                val pung = tiles.filter { it != Tile.Joker && it != Tile.Flower }.groupingBy { it }.eachCount()
                    .filter { it.value >= 3 }.keys.sortedBy { it.spokenName }.firstOrNull()
                when {
                    pung != null -> "This rack holds three or more ${pung.spokenName}, and Singles & Pairs never uses a pung."
                    Tile.Joker in tiles -> "Singles & Pairs never takes jokers, so the joker on this rack could not help it."
                    else -> generic
                }
            }
        }
    }

    /** "5s", "5s and 7s", "1s, 3s and 7s". */
    private fun plural(ranks: List<Int>): String {
        val words = ranks.map { "${it}s" }
        if (words.size <= 1) return words.firstOrNull() ?: ""
        return words.dropLast(1).joinToString(", ") + " and " + words.last()
    }

    fun explain(tiles: List<Tile>, answer: HandCategory): String {
        val list = suitedRanks(tiles).sorted().joinToString(", ")
        return when (answer) {
            HandCategory.EVENS_2468 -> "Every number on this rack is even ($list), with no honors at all. That is 2468 territory, and every odd tile you pick up is dead weight for it."
            HandCategory.ODDS_13579 -> "Every number here is odd ($list). That points straight at 13579, the mirror image of the evens section."
            HandCategory.THREE_SIX_NINE -> "Every number here is a 3, 6 or 9. The 6 rules out a pure odds hand and the 3 or 9 rules out a pure evens hand, so 369 is the read."
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
        // The core must read as this section and nothing else (iOS parity).
        if (RackGenerator.category(core) != section || !RackGenerator.isClean(core, section)) return null

        val strays = outsiders(section, 1, source) ?: return null
        val rack = (core + strays).racked
        if (rack.size != 13) return null
        // The stray must not change what the rack reads as (iOS parity).
        val fullRead = RackGenerator.category(rack)
        if ((fullRead != null && fullRead != section) || completesRun(strays[0], core)) return null

        val answer = strays[0]
        groupLeaders.shuffleSwift(source)
        val distractors = groupLeaders.take(3)
        if (distractors.size != 3) return null

        val choices = (listOf(answer) + distractors).toMutableList()
        choices.shuffleSwift(source)

        val notes = choices.map { tile ->
            if (tile == answer) null else note(tile, rack.count { it == tile })
        }
        return GeneratedPass(rack, section, answer, choices, explain(rack, section, answer), notes)
    }

    /**
     * The stricter test Endless Practice applies on top of `build` (iOS 2026-10-18 answer
     * audit): the stray must be nothing to any hand a player could argue for.
     * - Addition hands: not when a number stray and every other number on the rack are digits
     *   of one sum (4, 9, 1 and 3 read as 4 + 9 = 13), with or without a two-singles keeper.
     * - Year hands: never a Soap stray beside a 2, 6 or 7, since the Soap writes the year's
     *   zero, never a 2, 6 or 7 stray beside Soaps or on a Winds & Dragons rack, and never a
     *   wind or dragon stray beside a 2 and a 6 or 7 (2026, 2027).
     */
    fun isUnarguable(pass: GeneratedPass): Boolean {
        val ranks = suitedRanks(pass.tiles)
        val strayRank = (pass.answer as? Tile.Suited)?.rank
        if (strayRank != null && ranks.size >= 3 && DefenseGenerator.fitsOneSum(ranks)) return false
        // A two-singles rack must not fit one sum without its keeper either: 4 + 8 = 12 holds a
        // stray 1 once the keeper 6 goes, and then passing the keeper is just as right.
        if (strayRank != null) {
            val otherSingles = pass.tiles.filter { tile -> tile != pass.answer && pass.tiles.count { it == tile } == 1 }
            for (single in otherSingles) {
                val rest = pass.tiles.toMutableList().apply { remove(single) }
                val restRanks = suitedRanks(rest)
                if (restRanks.size >= 3 && DefenseGenerator.fitsOneSum(restRanks)) return false
            }
        }
        val yearDigits = setOf(2, 6, 7)
        val hasYearStart = 2 in ranks && (6 in ranks || 7 in ranks)
        val strayIsYearDigit = strayRank != null && strayRank in yearDigits
        if (pass.answer == Tile.DragonTile(Dragon.SOAP) && ranks.any { it in yearDigits }) return false
        // A 2 with a 6 or 7 on the rack is two of the year's digits, so neither is a stray.
        if (strayIsYearDigit && hasYearStart) return false
        // A 2, 6 or 7 on an honors rack could be a year written beside winds.
        if (pass.section == HandCategory.WINDS_DRAGONS && strayIsYearDigit) return false
        // The mirror case: a 2, 6 or 7 stray beside Soaps reads as a year start.
        if (Tile.DragonTile(Dragon.SOAP) in pass.tiles && strayIsYearDigit) return false
        // And a wind or dragon stray beside a 2 and a 6 or 7: the year can be written beside
        // honors, so the stray is not nothing.
        if ((pass.answer is Tile.WindTile || pass.answer is Tile.DragonTile) && hasYearStart) return false
        return true
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

    /** Whether a numbered stray would sit in a three-in-a-row with the core's numbers. */
    fun completesRun(stray: Tile, core: List<Tile>): Boolean {
        val rank = (stray as? Tile.Suited)?.rank ?: return false
        val ranks = core.mapNotNull { (it as? Tile.Suited)?.rank }.toSet() + rank
        return (rank - 2..rank).any { start -> (start..start + 2).all { it in ranks } }
    }

    fun note(tile: Tile, held: Int): String {
        val cost = when {
            held >= 4 -> "Passing one turns a kong back into a pung"
            held == 3 -> "Passing one breaks up a pung you have already made"
            else -> "Passing one splits a pair"
        }
        return "You hold $held of the ${tile.spokenName}. $cost, when another tile on this rack costs you nothing."
    }

    fun explain(rack: List<Tile>, section: HandCategory, answer: Tile): String {
        val copies = rack.count { it == answer }
        val alone = if (copies == 1) "your only single tile"
        else "$copies of a tile nothing else on the rack works with"
        return "This rack is pointed at ${section.displayName}. The ${answer.spokenName} is $alone. It might fit some hand, but every other choice is part of a group you have already built, so it is the one tile you can pass without breaking anything. Junk goes on the first pass."
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
        // Every bait tile must feed every section the exposures fit (3 and 9
        // read as 369 and as odds), or a second reading makes it safe.
        val readings = sectionsFitting(exposed)
        val bait = dangerous.drop(2).filter { tile -> readings.all { fits(tile, it) } }.take(3)
        if (bait.size != 3) return null
        val exposures = exposed.map { tile -> List(3) { tile } }

        val safe = safeTile(readings, exposed, exposed + bait, source) ?: return null
        val choices = (bait + safe).toMutableList()
        choices.shuffleSwift(source)

        val notes = choices.map { tile ->
            if (tile == safe) null
            else "The ${tile.spokenName} fits ${readingNames(readings)}, which is where those exposures point. Late in a hand it could be the tile that hands them the game."
        }
        return GeneratedDefense(exposures, section, safe, choices, explain(exposures, section, safe), notes)
    }

    private fun dangerousTiles(section: HandCategory): List<Tile> = when (section) {
        HandCategory.EVENS_2468 -> Tile.suited(listOf(2, 4, 6, 8))
        HandCategory.ODDS_13579 -> Tile.suited(listOf(1, 3, 5, 7, 9))
        HandCategory.THREE_SIX_NINE -> Tile.suited(listOf(3, 6, 9))
        else -> emptyList()
    }

    /**
     * The stricter test Endless Practice applies on top of `build`, for readings a card can
     * still hold (iOS 2026-10-18 content audit):
     * - Addition hands: no safe tile that makes a sum with the two exposed numbers (5 and 7
     *   with a 2, or 1 and 7 with a 2, read as 5 + 7 = 12).
     * - Runs: the safe tile and both exposures span seven numbers or more, wider than any run
     *   that has room for two pungs.
     * - Year: never pungs of 2s and 6s, which also spell 2026.
     */
    fun isUnarguable(question: GeneratedDefense): Boolean {
        val exposed = question.exposures.mapNotNull { (it.firstOrNull() as? Tile.Suited)?.rank }
        val safe = (question.answer as? Tile.Suited)?.rank
        if (exposed.size != 2 || safe == null) return false
        val all = exposed + safe
        if (all.max() - all.min() < 6) return false
        if (exposed.toSet() == setOf(2, 6)) return false
        return !makesSum(exposed[0], exposed[1], safe)
    }

    private fun sumDigits(a: Int, b: Int): List<Int> = listOf(a, b) + (a + b).toString().map { it.digitToInt() }

    /**
     * Whether three numbers can all sit in one written sum a + b = c, the digits of c included:
     * 5 + 7 = 12 holds a 1, 2, 5 and 7, so any three of those can be argued into an addition hand.
     */
    fun makesSum(x: Int, y: Int, z: Int): Boolean = (1..9).any { a ->
        (a..9).any { b ->
            val digits = sumDigits(a, b).toMutableList()
            listOf(x, y, z).all { digits.remove(it) }
        }
    }

    /** Whether every number on a rack is a digit of one written sum (4, 9, 1 and 3 are 4 + 9 = 13). */
    fun fitsOneSum(ranks: Set<Int>): Boolean {
        if (ranks.isEmpty()) return false
        return (1..9).any { a -> (a..9).any { b -> sumDigits(a, b).toSet().containsAll(ranks) } }
    }

    /** Every readable section that holds all the exposed tiles. */
    fun sectionsFitting(exposed: List<Tile>): List<HandCategory> =
        readableSections.filter { section -> exposed.all { fits(it, section) } }

    fun fits(tile: Tile, section: HandCategory): Boolean {
        val rank = (tile as? Tile.Suited)?.rank ?: return false
        return fitsRank(rank, section)
    }

    private fun fitsRank(rank: Int, section: HandCategory): Boolean = when (section) {
        HandCategory.EVENS_2468 -> rank % 2 == 0
        HandCategory.ODDS_13579 -> rank % 2 != 0
        HandCategory.THREE_SIX_NINE -> rank % 3 == 0
        else -> false
    }

    private fun safeTile(readings: List<HandCategory>, exposed: List<Tile>, used: List<Tile>, source: RandomSource): Tile? {
        if (readings.isEmpty()) return null
        val exposedRanks = exposed.mapNotNull { (it as? Tile.Suited)?.rank }
        val low = exposedRanks.minOrNull() ?: return null
        val high = exposedRanks.max()
        val sameParity = exposedRanks.all { it % 2 == low % 2 }

        val safeRanks = (1..9).filter { candidate ->
            val outsideSections = readings.all { !fitsRank(candidate, it) }
            val outsideRun = maxOf(high, candidate) - minOf(low, candidate) > 4
            val outsideParity = !sameParity || (candidate % 2 == 0) != (low % 2 == 0)
            outsideSections && outsideRun && outsideParity
        }
        val pool = Tile.suited(safeRanks).filter { it !in used }.toMutableList()
        pool.shuffleSwift(source)
        return pool.firstOrNull()
    }

    /** The suit both tiles are in, or null when they differ. */
    private fun sharedSuit(tiles: List<Tile>): Suit? {
        val suits = tiles.mapNotNull { (it as? Tile.Suited)?.suit }
        if (suits.size != tiles.size || suits.isEmpty() || suits.any { it != suits[0] }) return null
        return suits[0]
    }

    /** "369", or "369 and 13579 (Odds)" when the exposures fit both. */
    fun readingNames(readings: List<HandCategory>): String = readings.joinToString(" and ") { it.displayName }

    fun explain(exposures: List<List<Tile>>, section: HandCategory, safe: Tile): String {
        val shown = exposures.mapNotNull { it.firstOrNull() }.joinToString(" and a pung of ") { it.spokenName }
        val readings = sectionsFitting(exposures.mapNotNull { it.firstOrNull() })
        val exposedRanks = exposures.mapNotNull { (it.firstOrNull() as? Tile.Suited)?.rank }
        // Pungs in one suit within five numbers of each other can also sit in a run. A run is
        // one suit, so pungs in two suits get no run sentence (iOS parity).
        val runSuit = sharedSuit(exposures.mapNotNull { it.firstOrNull() })
        val runPossible = runSuit != null && (exposedRanks.maxOrNull() ?: 0) - (exposedRanks.minOrNull() ?: 0) <= 4
        var read = if (readings.size > 1) "A pung of $shown fit both ${readingNames(readings)}, so read the table both ways."
        else "A pung of $shown both sit inside ${section.displayName}, so that is the family their exposures point to."
        if (runPossible) read += " A Consecutive Run in ${runSuit.displayName}s from ${exposedRanks.min()} to ${exposedRanks.max()} could hold both, too."
        val value = (safe as? Tile.Suited)?.rank ?: 0
        val article = if (value == 8) "an" else "a"
        val never = readings.map { "${it.displayName} never uses $article $value" }.toMutableList()
        if (runPossible) never += "no run through both of them reaches $article $value"
        return "$read The ${safe.spokenName} fits none of it: ${never.joinToString(", and ")}. Of these four it is the safest throw, because every other choice feeds what they are showing."
    }
}
