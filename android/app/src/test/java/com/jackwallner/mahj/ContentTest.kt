package com.jackwallner.mahj

import com.jackwallner.mahj.content.CharlestonGenerator
import com.jackwallner.mahj.content.DefenseGenerator
import com.jackwallner.mahj.content.DrillLibrary
import com.jackwallner.mahj.content.EndlessPractice
import com.jackwallner.mahj.content.HandPlayEngine
import com.jackwallner.mahj.content.MahjContent
import com.jackwallner.mahj.content.PracticeSkill
import com.jackwallner.mahj.content.RackGenerator
import com.jackwallner.mahj.content.SessionBuilder
import com.jackwallner.mahj.model.DrillKind
import com.jackwallner.mahj.model.HandCategory
import com.jackwallner.mahj.model.Tile
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** Content rules and generator properties, checked against the exported library and random deals. */
class ContentTest {
    private fun copiesOk(tiles: List<Tile>) = tiles.groupingBy { it }.eachCount().all { (tile, count) ->
        count <= if (tile == Tile.Flower || tile == Tile.Joker) 8 else 4
    }

    @Test
    fun libraryMatchesTheIosShape() {
        val rooms = DrillLibrary.rooms
        assertEquals(listOf("tile-room", "card-room", "charleston-room", "table-room", "pro-tables"), rooms.map { it.id })
        assertTrue(rooms.take(4).all { it.isFree })
        assertFalse(rooms.last().isFree)
        rooms.take(4).forEach { room -> assertEquals(1, room.drills.count { it.isPlus }) }
        val ids = rooms.flatMap { room ->
            room.drills.flatMap { drill ->
                when (val kind = drill.kind) {
                    is DrillKind.Flashcards -> kind.cards.map { it.id }
                    is DrillKind.Quiz -> kind.questions.map { it.id }
                    is DrillKind.HandMatch -> kind.questions.map { it.id }
                    is DrillKind.Charleston -> kind.scenarios.map { it.id }
                }
            }
        }
        assertEquals("Every content id is unique", ids.size, ids.toSet().size)
    }

    @Test
    fun dealsAndPassesAreLegal() {
        DrillLibrary.rooms.flatMap { it.drills }.forEach { drill ->
            when (val kind = drill.kind) {
                is DrillKind.HandMatch -> kind.questions.forEach {
                    assertEquals(it.id, 13, it.tiles.size)
                    assertTrue(it.answer in it.choices)
                    assertTrue(copiesOk(it.tiles))
                }
                is DrillKind.Charleston -> kind.scenarios.forEach { scenario ->
                    assertEquals(13, scenario.deal.size)
                    assertEquals(3, scenario.recommendedPass.size)
                    assertFalse(Tile.Joker in scenario.recommendedPass)
                    val pool = scenario.deal.toMutableList()
                    scenario.recommendedPass.forEach { assertTrue(scenario.id, pool.remove(it)) }
                }
                is DrillKind.Quiz -> kind.questions.forEach { assertTrue(it.answerIndex in it.choices.indices) }
                is DrillKind.Flashcards -> kind.cards.forEach { card ->
                    card.choice?.let { assertEquals(2, it.options.size); assertTrue(it.answerIndex in 0..1) }
                }
            }
        }
    }

    @Test
    fun noEmDashesAnywhereInTheExportedCopy() {
        val raw = javaClass.classLoader!!.getResourceAsStream("mahj-content.json")!!.bufferedReader().readText()
        assertFalse(raw.contains('—'))
        assertNotNull(MahjContent.library)
    }

    @Test
    fun quickSessionPrioritisesMissesAndRespectsTheLock() {
        val freeIds = SessionBuilder.reviewableIDs(false)
        val missed = freeIds.take(3).toSet()
        val session = SessionBuilder.quickSession(seen = freeIds, missed = missed, includePro = false)
        assertEquals(10, session.size)
        assertEquals(missed, session.take(3).map { it.id }.toSet())
        assertTrue("Free players never get Mahj+ items", session.all { it.id in freeIds })
        assertTrue(SessionBuilder.reviewableIDs(true).containsAll(freeIds))
    }

    @Test
    fun generatedRacksAreUnambiguousAndLegal() {
        repeat(40) {
            RackGenerator.batch(5).forEach { rack ->
                assertEquals(13, rack.tiles.size)
                assertEquals(rack.answer, RackGenerator.category(rack.tiles))
                assertTrue(rack.answer in rack.choices)
                assertTrue(rack.choices.filter { it != rack.answer }.none { RackGenerator.fits(rack.tiles, it) })
                assertTrue(copiesOk(rack.tiles))
            }
        }
    }

    @Test
    fun generatedPassesOfferExactlyOneFreeTile() {
        repeat(200) {
            val pass = CharlestonGenerator.pass() ?: return@repeat
            assertEquals(13, pass.tiles.size)
            assertEquals(4, pass.choices.toSet().size)
            assertFalse(Tile.Joker in pass.choices)
            pass.choices.filter { it != pass.answer }.forEach { tile -> assertTrue(pass.tiles.count { it == tile } >= 3) }
            assertEquals(pass.choices.size, pass.choiceNotes.size)
            assertEquals(1, pass.choiceNotes.count { it == null })
        }
    }

    @Test
    fun defenseSafeDiscardIsNeverAnHonorOrExposed() {
        repeat(200) {
            val question = DefenseGenerator.question() ?: return@repeat
            assertEquals(4, question.choices.toSet().size)
            assertFalse(question.answer.isHonor)
            val exposed = question.exposures.map { it.first() }
            assertTrue(question.choices.none { it in exposed })
            assertTrue((question.exposures[0][0] as Tile.Suited).rank != (question.exposures[1][0] as Tile.Suited).rank)
        }
    }

    @Test
    fun everyEndlessSkillProducesUsableItems() {
        PracticeSkill.endlessCases.forEach { skill ->
            val items = EndlessPractice.items(skill, 6)
            assertTrue(skill.raw, items.isNotEmpty())
            items.forEach { item ->
                assertTrue(item.id.startsWith(skill.itemPrefix))
                assertTrue(item.answerIndex in item.choices.indices)
            }
        }
        assertTrue(EndlessPractice.items(PracticeSkill.HAND_PLAY, 5).isEmpty())
        assertEquals(10, EndlessPractice.mixedItems(10).size)
    }

    @Test
    fun handPlayNeverThrowsAJokerAndCostsAreNonNegative() {
        repeat(50) {
            val deal = HandPlayEngine.deal()
            assertEquals(152, deal.rack.size + deal.wall.size)
            HandPlayEngine.playableTargets.forEach { target ->
                val best = HandPlayEngine.bestDiscards(deal.rack, target)
                if (deal.rack.any { it != Tile.Joker }) assertFalse(Tile.Joker in best)
                deal.rack.forEach { assertTrue(HandPlayEngine.cost(it, deal.rack, target) >= 0) }
            }
        }
        assertEquals(RackGenerator.generatableCategories, HandPlayEngine.playableTargets)
        assertFalse(HandCategory.QUINTS in HandPlayEngine.playableTargets)
    }
}
