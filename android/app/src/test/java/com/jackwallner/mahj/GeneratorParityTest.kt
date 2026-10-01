package com.jackwallner.mahj

import com.jackwallner.mahj.content.CharlestonGenerator
import com.jackwallner.mahj.content.DefenseGenerator
import com.jackwallner.mahj.content.HandPlayEngine
import com.jackwallner.mahj.content.MahjMinuteContent
import com.jackwallner.mahj.content.QuickItem
import com.jackwallner.mahj.content.RackGenerator
import com.jackwallner.mahj.content.SessionBuilder
import com.jackwallner.mahj.model.ChoiceShuffle
import com.jackwallner.mahj.model.HandCategory
import com.jackwallner.mahj.model.StableSeededGenerator
import com.jackwallner.mahj.model.Tile
import java.time.LocalDate
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Test

/**
 * Holds the Kotlin generators to the iOS output recorded in
 * `mahj-parity.json` by `scripts/sync-android-content.sh`. A shared daily
 * challenge has to deal the same tiles on both platforms.
 */
class GeneratorParityTest {
    private val parity: JSONObject by lazy {
        val stream = javaClass.classLoader!!.getResourceAsStream("mahj-parity.json")!!
        JSONObject(stream.bufferedReader().use { it.readText() })
    }

    private fun JSONArray.strings() = (0 until length()).map { getString(it) }
    private fun JSONArray.ints() = (0 until length()).map { getInt(it) }
    private fun JSONArray.objects() = (0 until length()).map { getJSONObject(it) }
    private fun JSONArray.nullableStrings() = (0 until length()).map { if (isNull(it)) null else getString(it) }
    private fun codes(tiles: List<Tile>) = tiles.map { it.shortLabel }

    @Test
    fun seededStreamMatchesSwift() {
        val streams = parity.getJSONObject("streams")
        for (seed in streams.keys()) {
            val generator = StableSeededGenerator(seed)
            val actual = (0 until 8).map { generator.next().toString() }
            assertEquals("seed '$seed'", streams.getJSONArray(seed).strings(), actual)
        }
    }

    @Test
    fun permutationsMatchSwift() {
        val permutations = parity.getJSONObject("permutations")
        for (key in permutations.keys()) {
            val (seed, count) = key.split("|")
            assertEquals(key, permutations.getJSONArray(key).ints(), ChoiceShuffle.permutation(count.toInt(), seed))
        }
    }

    @Test
    fun rackBatchesMatchSwift() {
        val racks = parity.getJSONObject("racks")
        for (seed in racks.keys()) {
            val expected = racks.getJSONArray(seed).objects()
            val actual = RackGenerator.batch(7, seed)
            assertEquals(seed, expected.size, actual.size)
            expected.zip(actual).forEach { (want, got) ->
                assertEquals(want.getJSONArray("tiles").strings(), codes(got.tiles))
                assertEquals(want.getString("answer"), got.answer.raw)
                assertEquals(want.getJSONArray("choices").strings(), got.choices.map { it.raw })
                assertEquals(want.getString("explanation"), got.explanation)
            }
        }
    }

    @Test
    fun passBatchesMatchSwift() {
        val passes = parity.getJSONObject("passes")
        for (seed in passes.keys()) {
            val expected = passes.getJSONArray(seed).objects()
            val actual = CharlestonGenerator.batch(7, seed)
            assertEquals(seed, expected.size, actual.size)
            expected.zip(actual).forEach { (want, got) ->
                assertEquals(want.getJSONArray("tiles").strings(), codes(got.tiles))
                assertEquals(want.getString("section"), got.section.raw)
                assertEquals(want.getString("answer"), got.answer.shortLabel)
                assertEquals(want.getJSONArray("choices").strings(), codes(got.choices))
                assertEquals(want.getString("explanation"), got.explanation)
                assertEquals(want.getJSONArray("choiceNotes").nullableStrings(), got.choiceNotes)
            }
        }
    }

    @Test
    fun defenseBatchesMatchSwift() {
        val defenses = parity.getJSONObject("defenses")
        for (seed in defenses.keys()) {
            val expected = defenses.getJSONArray(seed).objects()
            val actual = DefenseGenerator.batch(7, seed)
            assertEquals(seed, expected.size, actual.size)
            expected.zip(actual).forEach { (want, got) ->
                val exposures = want.getJSONArray("exposures").let { list -> (0 until list.length()).map { list.getJSONArray(it).strings() } }
                assertEquals(exposures, got.exposures.map(::codes))
                assertEquals(want.getString("section"), got.impliedSection.raw)
                assertEquals(want.getString("answer"), got.answer.shortLabel)
                assertEquals(want.getJSONArray("choices").strings(), codes(got.choices))
                assertEquals(want.getString("explanation"), got.explanation)
                assertEquals(want.getJSONArray("choiceNotes").nullableStrings(), got.choiceNotes)
            }
        }
    }

    @Test
    fun handPlayMatchesSwift() {
        val deals = parity.getJSONObject("deals")
        for (seed in deals.keys()) {
            val deal = HandPlayEngine.deal(seed)
            val want = deals.getJSONObject(seed)
            assertEquals(want.getJSONArray("rack").strings(), codes(deal.rack))
            assertEquals(want.getJSONArray("wall").strings(), codes(deal.wall))
        }
        for (row in parity.getJSONArray("handPlay").objects()) {
            val rack = HandPlayEngine.deal(row.getString("seed")).rack
            val target = HandCategory.fromRaw(row.getString("target"))
            val discard = Tile.fromCode(row.getString("discard"))
            val best = HandPlayEngine.bestDiscards(rack, target)
            assertEquals(row.getDouble("value"), HandPlayEngine.value(rack, target), 1e-9)
            assertEquals(row.getJSONArray("best").strings(), codes(best.sortedBy { it.sortKey }))
            assertEquals(row.getDouble("cost"), HandPlayEngine.cost(discard, rack, target), 1e-9)
            assertEquals(row.getString("note"), HandPlayEngine.coachNote(discard, rack, target, discard in best))
            assertEquals(row.getInt("fitting"), HandPlayEngine.fittingTiles(rack, target))
            assertEquals(row.getInt("working"), HandPlayEngine.workingTiles(rack, target))
        }
        val verdictRack = HandPlayEngine.deal("verdict").rack
        for (row in parity.getJSONArray("verdicts").objects()) {
            val verdict = HandPlayEngine.verdict(
                verdictRack,
                HandCategory.fromRaw(row.getString("target")),
                row.getInt("clean"),
                row.getInt("discards"),
            )
            assertEquals(row.getInt("stars"), verdict.stars)
            assertEquals(row.getString("headline"), verdict.headline)
            assertEquals(row.getString("body"), verdict.body)
        }
    }

    private fun assertItem(want: JSONObject, got: QuickItem) {
        assertEquals(want.getString("id"), got.id)
        assertEquals(want.getString("prompt"), got.prompt)
        assertEquals(want.getJSONArray("tiles").strings(), codes(got.tiles))
        assertEquals(want.getJSONArray("choices").strings(), got.choices)
        assertEquals(want.getInt("answerIndex"), got.answerIndex)
        assertEquals(want.getString("explanation"), got.explanation)
        assertEquals(want.getString("sourceLabel"), got.sourceLabel)
        assertEquals(want.getString("roomID"), got.roomID)
        assertEquals(want.getString("trackingID"), got.trackingID)
        assertEquals(want.getBoolean("isReviewable"), got.isReviewable)
        assertEquals(want.getJSONArray("choiceNotes").nullableStrings(), got.paddedNotes)
    }

    @Test
    fun mahjMinuteMatchesSwift() {
        val minutes = parity.getJSONObject("minutes")
        for (day in minutes.keys()) {
            val want = minutes.getJSONObject(day)
            val challenge = MahjMinuteContent.challenge(LocalDate.parse(day))
            assertEquals(want.getString("shortDate"), challenge.shortDate)
            val questions = want.getJSONArray("questions").objects()
            assertEquals(day, questions.size, challenge.questions.size)
            questions.zip(challenge.questions).forEach { (wantQuestion, got) ->
                assertEquals(wantQuestion.getString("category"), got.category.raw)
                assertItem(wantQuestion.getJSONObject("item"), got.item)
            }
        }
    }

    @Test
    fun preparedChoicePoolMatchesSwift() {
        val expected = parity.getJSONArray("choicePool").objects()
        val actual = listOf("tile-room", "card-room", "charleston-room", "table-room", "pro-tables")
            .flatMap { SessionBuilder.choiceItems(it, includePro = true) }
            .map(SessionBuilder::prepared)
        assertEquals(expected.size, actual.size)
        expected.zip(actual).forEach { (want, got) -> assertItem(want, got) }
        assertEquals(parity.getJSONArray("freeReviewable").strings(), SessionBuilder.reviewableIDs(false).sorted())
        assertEquals(parity.getJSONArray("memberReviewable").strings(), SessionBuilder.reviewableIDs(true).sorted())
    }
}
