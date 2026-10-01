package com.jackwallner.mahj.content

import com.jackwallner.mahj.model.CharlestonScenario
import com.jackwallner.mahj.model.ChoiceShuffle
import com.jackwallner.mahj.model.Drill
import com.jackwallner.mahj.model.DrillKind
import com.jackwallner.mahj.model.StableSeededGenerator
import com.jackwallner.mahj.model.Tile
import com.jackwallner.mahj.model.racked
import java.time.LocalDate
import java.util.Locale

enum class MahjMinuteCategory(val raw: String, val title: String, val icon: String) {
    RACK_READING("rackReading", "Rack Reading", "square.grid.3x3.fill"),
    CHARLESTON("charleston", "Charleston", "arrow.triangle.2.circlepath"),
    TABLE_JUDGMENT("tableJudgment", "Table Judgment", "hand.point.up.left.fill"),
}

data class MahjMinuteQuestion(val category: MahjMinuteCategory, val item: QuickItem)

data class MahjMinuteChallenge(
    val day: LocalDate,
    val dayKey: String,
    val shortDate: String,
    val questions: List<MahjMinuteQuestion>,
) {
    val items: List<QuickItem> get() = questions.map { it.item }
}

/**
 * One shared five-question set per calendar date, identical to the iOS set for
 * the same date: racks from the seeded generator, the Charleston and table
 * calls picked from authored content with the same seeds.
 */
object MahjMinuteContent {
    const val QUESTION_COUNT = 5

    val drill = Drill("mahj-minute", "Mahj Minute", "Today's shared five-question challenge", DrillKind.Quiz(emptyList()), isPlus = true)

    fun key(day: LocalDate): String = String.format(Locale.US, "%04d-%02d-%02d", day.year, day.monthValue, day.dayOfMonth)

    fun challenge(day: LocalDate = LocalDate.now()): MahjMinuteChallenge {
        val dayKey = key(day)
        val racks = rackQuestions(dayKey)
        val charleston = charlestonQuestion(dayKey)
        val table = tableQuestions(dayKey)
        val questions = buildList {
            racks.getOrNull(0)?.let(::add)
            add(charleston)
            table.getOrNull(0)?.let(::add)
            racks.getOrNull(1)?.let(::add)
            table.getOrNull(1)?.let(::add)
        }
        val shortDate = String.format(Locale.US, "%02d/%02d", day.monthValue, day.dayOfMonth)
        return MahjMinuteChallenge(day, dayKey, shortDate, questions)
    }

    private fun rackQuestions(dayKey: String): List<MahjMinuteQuestion> =
        RackGenerator.batch(2, "mahj-minute-$dayKey-racks").mapIndexed { index, rack ->
            val item = QuickItem(
                id = PracticeSkill.RACK_READING.itemPrefix + "minute-$dayKey-$index",
                prompt = "Which section is this rack chasing?",
                tiles = rack.tiles,
                choices = rack.choices.map { it.displayName },
                answerIndex = rack.choices.indexOf(rack.answer).coerceAtLeast(0),
                explanation = rack.explanation,
                sourceLabel = "Mahj Minute: Rack Read",
                roomID = PracticeSkill.RACK_READING.roomID,
                trackingID = PracticeSkill.RACK_READING.raw,
                isReviewable = false,
            )
            MahjMinuteQuestion(MahjMinuteCategory.RACK_READING, SessionBuilder.prepared(item))
        }

    private fun charlestonQuestion(dayKey: String): MahjMinuteQuestion {
        val scenarios = DrillLibrary.rooms.flatMap { room ->
            room.drills.flatMap { (it.kind as? DrillKind.Charleston)?.scenarios ?: emptyList() }
        }
        val generator = StableSeededGenerator("mahj-minute-$dayKey-charleston")
        val scenario = scenarios[(generator.next() % scenarios.size.toULong()).toInt()]
        val answer = passLabel(scenario.recommendedPass)
        val item = QuickItem(
            id = "mahj-minute-charleston-$dayKey",
            prompt = "${scenario.situation} Which three tiles make the strongest pass?",
            tiles = scenario.deal.racked,
            choices = listOf(answer) + distractorPassLabels(scenario, dayKey),
            answerIndex = 0,
            explanation = scenario.reasoning,
            sourceLabel = "Mahj Minute: Charleston",
            roomID = "charleston-room",
            trackingID = "mahj-minute-charleston",
            isReviewable = false,
        )
        return MahjMinuteQuestion(MahjMinuteCategory.CHARLESTON, SessionBuilder.prepared(item))
    }

    private fun tableQuestions(dayKey: String): List<MahjMinuteQuestion> {
        val pool = SessionBuilder.choiceItems("table-room", includePro = true)
        val indices = ChoiceShuffle.permutation(pool.size, "mahj-minute-$dayKey-table")
        return indices.take(2).map { MahjMinuteQuestion(MahjMinuteCategory.TABLE_JUDGMENT, SessionBuilder.prepared(pool[it])) }
    }

    private fun distractorPassLabels(scenario: CharlestonScenario, seed: String): List<String> {
        val passable = scenario.deal.filter { it != Tile.Joker }
        val labels = mutableSetOf<String>()
        for (first in 0 until passable.size - 2) {
            for (second in first + 1 until passable.size - 1) {
                for (third in second + 1 until passable.size) {
                    val pass = listOf(passable[first], passable[second], passable[third])
                    // A distractor sharing two tiles with the answer would mark an equally good pass wrong.
                    if (overlap(pass, scenario.recommendedPass) > 1) continue
                    labels += passLabel(pass)
                }
            }
        }
        val sorted = labels.sorted()
        val order = ChoiceShuffle.permutation(sorted.size, "mahj-minute-$seed-passes")
        return order.take(3).map { sorted[it] }
    }

    private fun overlap(pass: List<Tile>, answer: List<Tile>): Int {
        val pool = answer.toMutableList()
        return pass.count { tile -> pool.indexOf(tile).takeIf { it >= 0 }?.let { pool.removeAt(it) } != null }
    }

    private fun passLabel(tiles: List<Tile>): String = tiles.racked.joinToString(", ") { it.spokenName }
}
