package com.jackwallner.mahj.content

import com.jackwallner.mahj.model.Drill
import com.jackwallner.mahj.model.DrillKind
import com.jackwallner.mahj.model.HandCategory
import com.jackwallner.mahj.model.Tile
import java.util.UUID
import kotlin.random.Random

enum class PracticeSkill(val raw: String, val title: String, val subtitle: String, val icon: String, val roomID: String) {
    RACK_READING("rackReading", "Read the Rack", "Freshly dealt racks, unlimited reps", "square.grid.3x3.fill", "card-room"),
    TILE_COUNTING("tileCounting", "Count What's Left", "Track the tiles still in play", "number.circle.fill", "table-room"),
    CHARLESTON_PASS("charlestonPass", "Pass the Junk", "Find the tile that fits nothing", "arrow.triangle.2.circlepath", "charleston-room"),
    DEFENSE("defense", "Read the Exposures", "Discard without feeding the table", "shield.lefthalf.filled", "table-room"),

    /** Play a Hand. Here only so its graded throws roll up into one stats row. */
    HAND_PLAY("handPlay", "Play a Hand", "Commit to a section and play it out", "hand.draw.fill", "card-room");

    /** Every generated item carries this prefix so stats roll it up into one row. */
    val itemPrefix: String get() = "gen-$raw-"

    companion object {
        val endlessCases: List<PracticeSkill> get() = entries.filter { it != HAND_PLAY }

        fun fromRaw(raw: String): PracticeSkill? = entries.firstOrNull { it.raw == raw }

        fun skill(forItemID: String): PracticeSkill? = entries.firstOrNull { forItemID.startsWith(it.itemPrefix) }
    }
}

/** Generated practice: procedural generators turned into the same QuickItem shape as authored drills. */
object EndlessPractice {
    fun drill(skill: PracticeSkill) = Drill("endless-${skill.raw}", skill.title, skill.subtitle, DrillKind.Quiz(emptyList()))

    val challengeDrill = Drill("timed-challenge", "Timed Challenge", "Beat the clock", DrillKind.Quiz(emptyList()))

    fun items(skill: PracticeSkill, count: Int): List<QuickItem> = when (skill) {
        PracticeSkill.RACK_READING -> rackItems(count)
        PracticeSkill.TILE_COUNTING -> countingItems(count)
        PracticeSkill.CHARLESTON_PASS -> passItems(count)
        PracticeSkill.DEFENSE -> defenseItems(count)
        PracticeSkill.HAND_PLAY -> emptyList()
    }

    /** A mixed batch across every skill, for the timed challenge. */
    fun mixedItems(count: Int): List<QuickItem> {
        val skills = PracticeSkill.endlessCases
        val perSkill = maxOf(1, count / skills.size + 1)
        return skills.flatMap { items(it, perSkill) }.shuffled().take(count)
    }

    private fun newID(skill: PracticeSkill) = skill.itemPrefix + UUID.randomUUID().toString().uppercase()

    private fun rackItems(count: Int): List<QuickItem> = RackGenerator.batch(count).map { rack ->
        QuickItem(
            id = newID(PracticeSkill.RACK_READING),
            prompt = "Which section is this rack chasing?",
            tiles = rack.tiles,
            choices = rack.choices.map { it.displayName },
            answerIndex = rack.choices.indexOf(rack.answer).coerceAtLeast(0),
            explanation = rack.explanation,
            sourceLabel = "Endless Practice",
            roomID = PracticeSkill.RACK_READING.roomID,
            choiceNotes = HandCategory.missNotes(rack.choices, rack.answer),
        )
    }

    /** Four of every suited tile, wind and dragon exist. */
    private fun countingItems(count: Int): List<QuickItem> {
        val items = mutableListOf<QuickItem>()
        while (items.size < count) {
            if (Random.nextInt(0, 4) == 0) {
                items += jokerCountingItem()
                continue
            }
            val tile = randomCountableTile()
            val held = Random.nextInt(0, 3)
            val exposed = Random.nextInt(0, 4 - held)
            val remaining = 4 - held - exposed

            val values = sortedSetOf(remaining)
            for (offset in listOf(-2, -1, 1, 2)) if (remaining + offset in 0..4) values += remaining + offset
            val sorted = values.toList().take(4)
            val answerIndex = sorted.indexOf(remaining)
            if (answerIndex < 0 || sorted.size < 3) continue

            val heldPhrase = if (held == 0) "none on your rack" else "$held on your rack"
            val exposedPhrase = if (exposed == 0) "none showing on the table" else "$exposed exposed on other racks"
            items += QuickItem(
                id = newID(PracticeSkill.TILE_COUNTING),
                prompt = "You have $heldPhrase and can see $exposedPhrase. How many ${tile.spokenName}s are still unaccounted for?",
                tiles = List(held) { tile },
                choices = sorted.map { it.toString() },
                answerIndex = answerIndex,
                explanation = "Four of every tile exist. $held held plus $exposed exposed leaves $remaining unaccounted for. Jokers cannot stand in for a tile in a pair, so counting matters most when you are waiting on one.",
                sourceLabel = "Endless Practice",
                roomID = PracticeSkill.TILE_COUNTING.roomID,
            )
        }
        return items
    }

    /** Eight jokers in the set, and a discarded one is dead for good. */
    fun jokerCountingItem(): QuickItem {
        val held = Random.nextInt(0, 3)
        val exposed = Random.nextInt(0, 4)
        val discarded = Random.nextInt(0, 3)
        val remaining = 8 - held - exposed - discarded

        val values = sortedSetOf(remaining)
        for (offset in listOf(-2, -1, 1, 2)) if (remaining + offset in 0..8) values += remaining + offset
        val sorted = values.toList().take(4)
        val answerIndex = sorted.indexOf(remaining).coerceAtLeast(0)

        val heldPhrase = when (held) {
            0 -> "no jokers"
            1 -> "1 joker"
            else -> "$held jokers"
        }
        val exposedPhrase = if (exposed == 0) "none" else "$exposed"
        val discardedPhrase = if (discarded == 0) "none" else "$discarded"
        return QuickItem(
            id = newID(PracticeSkill.TILE_COUNTING),
            prompt = "You hold $heldPhrase. You can see $exposedPhrase in exposures and $discardedPhrase in the discards. How many jokers are still unseen?",
            tiles = List(held) { Tile.Joker },
            choices = sorted.map { it.toString() },
            answerIndex = answerIndex,
            explanation = "Eight jokers are in the set. $held held, $exposed exposed and $discarded discarded leaves $remaining unseen. The exposed ones are not gone: hold the matching real tile and you can swap one out on your turn.",
            sourceLabel = "Endless Practice",
            roomID = PracticeSkill.TILE_COUNTING.roomID,
        )
    }

    private fun passItems(count: Int): List<QuickItem> = CharlestonGenerator.batch(count).map { pass ->
        QuickItem(
            id = newID(PracticeSkill.CHARLESTON_PASS),
            prompt = "First pass, three tiles going right. Which of these can you lose for free?",
            tiles = pass.tiles,
            choices = pass.choices.map { it.spokenName },
            answerIndex = pass.choices.indexOf(pass.answer).coerceAtLeast(0),
            explanation = pass.explanation,
            sourceLabel = "Endless Practice",
            roomID = PracticeSkill.CHARLESTON_PASS.roomID,
            choiceNotes = pass.choiceNotes,
        )
    }

    private fun defenseItems(count: Int): List<QuickItem> = DefenseGenerator.batch(count).map { question ->
        val shown = question.exposures.mapNotNull { it.firstOrNull() }.joinToString(" and ") { "a pung of ${it.spokenName}" }
        QuickItem(
            id = newID(PracticeSkill.DEFENSE),
            prompt = "The only player with exposures has $shown on their rack. Which discard is safest?",
            tiles = question.exposures.flatten(),
            choices = question.choices.map { it.spokenName },
            answerIndex = question.choices.indexOf(question.answer).coerceAtLeast(0),
            explanation = question.explanation,
            sourceLabel = "Endless Practice",
            roomID = PracticeSkill.DEFENSE.roomID,
            choiceNotes = question.choiceNotes,
        )
    }

    /** Flowers and jokers are excluded: eight of each exist. */
    private fun randomCountableTile(): Tile = (Tile.allSuited + Tile.allHonors).random()
}
