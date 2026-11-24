package com.jackwallner.mahj

import com.jackwallner.mahj.content.Difficulty
import com.jackwallner.mahj.content.DrillLibrary
import com.jackwallner.mahj.content.ItemDifficulty
import com.jackwallner.mahj.content.QuickItem
import com.jackwallner.mahj.content.SessionBuilder
import com.jackwallner.mahj.content.SessionLevel
import com.jackwallner.mahj.data.AppClock
import com.jackwallner.mahj.data.InMemoryStore
import com.jackwallner.mahj.data.ProgressStore
import com.jackwallner.mahj.model.DrillKind
import java.time.Clock
import java.time.Instant
import java.time.ZoneOffset
import kotlin.math.ceil
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Port of iOS `SessionLevelTests`: the onboarding answer sets where a player starts, accuracy
 * opens the next tier, and nothing ever takes a tier away.
 */
class SessionLevelTest {
    private var defaults = InMemoryStore()
    private val clock = AppClock(Clock.fixed(Instant.parse("2026-11-24T12:00:00Z"), ZoneOffset.UTC))
    private var store = ProgressStore(defaults, clock)

    private fun fresh() {
        defaults = InMemoryStore()
        store = ProgressStore(defaults, clock)
    }

    private fun skill(level: String) = defaults.putString("mahj.skillLevel", level)

    private val libraryIDs: List<String>
        get() = DrillLibrary.rooms.flatMap { it.drills }.flatMap { drill ->
            when (val kind = drill.kind) {
                is DrillKind.Flashcards -> kind.cards.map { it.id }
                is DrillKind.Quiz -> kind.questions.map { it.id }
                is DrillKind.HandMatch -> kind.questions.map { it.id }
                is DrillKind.Charleston -> kind.scenarios.map { it.id }
            }
        }

    // The tags

    @Test
    fun everyLibraryItemHasATier() {
        val tagged = ItemDifficulty.tiers.keys
        val missing = libraryIDs.toSet() - tagged
        assertTrue("Untagged items: ${missing.sorted()}", missing.isEmpty())
        val stray = tagged - libraryIDs.toSet()
        assertTrue("Tagged ids not in the library: ${stray.sorted()}", stray.isEmpty())
    }

    /** A first-lesson player meets pung, kong and quint only in the questions that teach those words. */
    @Test
    fun basicQuestionsDoNotAssumeGroupWords() {
        val teaching = setOf("quiz-pung", "plus-tq-kong")
        val words = listOf("pung", "kong", "quint", "sextet")
        val basic = SessionBuilder.quickSession(1000, emptySet(), emptySet(), includePro = true, ceiling = Difficulty.BASIC)
            .filter { ItemDifficulty.of(it.id) == Difficulty.BASIC }
        assertTrue(basic.size >= 20)
        for (item in basic.filter { it.id !in teaching }) {
            val text = (listOf(item.prompt) + item.choices).joinToString(" ").lowercase()
            for (word in words) assertFalse("${item.id} is basic but asks about a $word", word in text)
        }
    }

    @Test
    fun freeBasicPoolFillsMoreThanOneSession() {
        val basic = SessionBuilder.poolIDs(false).filter { ItemDifficulty.of(it) == Difficulty.BASIC }
        assertTrue("A new free player needs more than one session of basics", basic.size >= 15)
    }

    // The seed

    @Test
    fun seedFollowsOnboarding() {
        assertEquals(Difficulty.BASIC, SessionLevel.seed("new"))
        assertEquals(Difficulty.INTERMEDIATE, SessionLevel.seed("basics"))
        assertEquals(Difficulty.CHALLENGING, SessionLevel.seed("played"))
        assertEquals("A player from before the question keeps the full mix", Difficulty.CHALLENGING, SessionLevel.seed(""))
    }

    // Sessions

    /** Plays sessions the way Home builds them, answering every question right. */
    private fun playSessions(count: Int, skillLevel: String, includePro: Boolean): List<List<QuickItem>> {
        skill(skillLevel)
        return (0 until count).map {
            val items = SessionBuilder.quickSession(
                seen = store.seenItems, missed = store.missedItems, includePro = includePro,
                ceiling = store.sessionCeiling(includePro),
            )
            items.forEach { store.recordItem(it.id, correct = true) }
            items
        }
    }

    @Test
    fun newPlayerFirstSessionsAreBasicThenNeverChallenging() {
        for (includePro in listOf(false, true)) {
            fresh()
            val sessions = playSessions(3, "new", includePro)
            for (item in sessions[0] + sessions[1]) {
                assertEquals("${item.id} reached a new player's first two sessions", Difficulty.BASIC, ItemDifficulty.of(item.id))
            }
            for (item in sessions.flatten()) {
                assertNotEquals("${item.id} reached a new player early", Difficulty.CHALLENGING, ItemDifficulty.of(item.id))
            }
            assertEquals(30, sessions.flatten().size)
        }
    }

    @Test
    fun playedPlayerGetsTheFullMix() {
        skill("played")
        val ceiling = store.sessionCeiling(true)
        assertEquals(Difficulty.CHALLENGING, ceiling)
        val mix = SessionBuilder.quickSession(500, emptySet(), emptySet(), includePro = true, ceiling = ceiling)
        assertEquals(Difficulty.entries.toSet(), mix.map { ItemDifficulty.of(it.id) }.toSet())
        assertEquals(SessionBuilder.poolIDs(true).size, mix.size)
    }

    @Test
    fun basicsPlayerStartsWithIntermediateButNoChallenging() {
        skill("basics")
        val ceiling = store.sessionCeiling(false)
        assertEquals(Difficulty.INTERMEDIATE, ceiling)
        val eligible = SessionBuilder.poolIDs(false).filter { ItemDifficulty.of(it) <= Difficulty.INTERMEDIATE }
        val mix = SessionBuilder.quickSession(eligible.size, emptySet(), emptySet(), includePro = false, ceiling = ceiling)
        assertEquals(setOf(Difficulty.BASIC, Difficulty.INTERMEDIATE), mix.map { ItemDifficulty.of(it.id) }.toSet())
        assertEquals(eligible.toSet(), mix.map { it.id }.toSet())
    }

    /** Answers `fraction` of the tier's pool, getting `accuracy` of them right. */
    private fun answer(tier: Difficulty, fraction: Double, accuracy: Double, includePro: Boolean) {
        val ids = SessionBuilder.poolIDs(includePro).filter { ItemDifficulty.of(it) == tier }
        val answered = ids.take(ceil(ids.size * fraction).toInt())
        val right = ceil(answered.size * accuracy).toInt()
        answered.forEachIndexed { index, id -> store.recordItem(id, correct = index < right) }
    }

    @Test
    fun eightyPercentOnBasicOpensIntermediate() {
        skill("new")
        answer(Difficulty.BASIC, 0.6, 0.8, includePro = false)
        val ceiling = store.sessionCeiling(false)
        assertEquals(Difficulty.INTERMEDIATE, ceiling)
        val next = SessionBuilder.quickSession(
            seen = store.seenItems, missed = store.missedItems, includePro = false, ceiling = ceiling,
        )
        assertTrue("Intermediate should start showing up", next.any { ItemDifficulty.of(it.id) == Difficulty.INTERMEDIATE })
        assertFalse(next.any { ItemDifficulty.of(it.id) == Difficulty.CHALLENGING })
    }

    @Test
    fun weakAccuracyOrThinCoverageStaysBasic() {
        skill("new")
        answer(Difficulty.BASIC, 1.0, 0.6, includePro = false)
        assertEquals("60% right is not most of the tier", Difficulty.BASIC, store.sessionCeiling(false))

        store.resetAll()
        answer(Difficulty.BASIC, 0.3, 1.0, includePro = false)
        assertEquals("A few perfect answers are not a tier", Difficulty.BASIC, store.sessionCeiling(false))
    }

    @Test
    fun missesComeBackFirstInsideTheCeiling() {
        skill("new")
        val missedID = SessionBuilder.poolIDs(false).first { ItemDifficulty.of(it) == Difficulty.BASIC }
        store.recordItem(missedID, correct = false)
        val next = SessionBuilder.quickSession(
            seen = store.seenItems, missed = store.missedItems, includePro = false,
            ceiling = store.sessionCeiling(false),
        )
        assertEquals(missedID, next.first().id)
    }

    @Test
    fun ceilingNeverDrops() {
        skill("new")
        answer(Difficulty.BASIC, 1.0, 1.0, includePro = false)
        assertEquals(Difficulty.INTERMEDIATE, store.sessionCeiling(false))
        answer(Difficulty.BASIC, 1.0, 0.0, includePro = false)
        assertEquals("A bad day keeps the tier already earned", Difficulty.INTERMEDIATE, store.sessionCeiling(false))
        assertEquals(
            "The reached tier survives a relaunch",
            Difficulty.INTERMEDIATE, ProgressStore(defaults, clock).sessionCeiling(false),
        )

        store.resetAll()
        assertEquals("Resetting progress goes back to the onboarding seed", Difficulty.BASIC, store.sessionCeiling(false))
    }

    @Test
    fun ceilingNeverFallsBelowTheSeed() {
        skill("basics")
        answer(Difficulty.BASIC, 1.0, 0.0, includePro = false)
        assertEquals(Difficulty.INTERMEDIATE, store.sessionCeiling(false))
    }

    @Test
    fun intermediateMasteryOpensChallenging() {
        skill("new")
        answer(Difficulty.BASIC, 1.0, 1.0, includePro = true)
        answer(Difficulty.INTERMEDIATE, 0.7, 0.9, includePro = true)
        assertEquals(Difficulty.CHALLENGING, store.sessionCeiling(true))
    }

    @Test
    fun smallPoolPadsWithTheEasiestTierAbove() {
        val basicCount = SessionBuilder.poolIDs(false).count { ItemDifficulty.of(it) == Difficulty.BASIC }
        val session = SessionBuilder.quickSession(basicCount + 5, emptySet(), emptySet(), includePro = false, ceiling = Difficulty.BASIC)
        assertEquals(basicCount + 5, session.size)
        assertEquals(basicCount, session.take(basicCount).count { ItemDifficulty.of(it.id) == Difficulty.BASIC })
        for (item in session.takeLast(5)) {
            assertEquals("Padding takes the next tier up first", Difficulty.INTERMEDIATE, ItemDifficulty.of(item.id))
        }
    }

    @Test
    fun gameNightPrepKeepsFreshMaterialUnderTheCeiling() {
        val challenging = SessionBuilder.poolIDs(true).first { ItemDifficulty.of(it) == Difficulty.CHALLENGING }
        val session = SessionBuilder.gameNightPrep(
            count = 10, seen = emptySet(), missed = setOf(challenging), dueIDs = emptyList(),
            weakestRoomID = "table-room", ceiling = Difficulty.BASIC,
        )
        assertEquals("A player's own miss still comes back", challenging, session.first().id)
        for (item in session.drop(1)) {
            assertEquals("${item.id} is above a basic player's ceiling", Difficulty.BASIC, ItemDifficulty.of(item.id))
        }
    }
}
