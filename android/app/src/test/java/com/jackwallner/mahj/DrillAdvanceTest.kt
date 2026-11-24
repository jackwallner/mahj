package com.jackwallner.mahj

import com.jackwallner.mahj.content.EndlessPractice
import com.jackwallner.mahj.content.SessionBuilder
import com.jackwallner.mahj.ui.screens.DrillNext
import com.jackwallner.mahj.ui.screens.advancedRun
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** Next advances once per answered question, and a generated run never keeps what it has answered. */
class DrillAdvanceTest {
    @Test
    fun nextNeedsAnAnswerAndARunningDrill() {
        assertTrue(DrillNext.allowed(answered = true, finished = false))
        assertFalse("The second tap of a double tap finds the next question unanswered", DrillNext.allowed(answered = false, finished = false))
        assertFalse("Nothing advances past the result", DrillNext.allowed(answered = true, finished = true))
    }

    @Test
    fun aGeneratedRunDropsAnsweredQuestions() {
        val first = EndlessPractice.mixedItems(8)
        var items = first
        var index = 0
        repeat(40) {
            val (next, nextIndex) = advancedRun(items, index, isGenerated = true) { EndlessPractice.mixedItems(8) }
            items = next
            index = nextIndex
            assertEquals(0, index)
            assertTrue("A long run holds a bounded list, not every question dealt", items.size <= 8 + 3)
            assertTrue(items.size > 3 - 1)
        }
        assertFalse(items.any { it in first.take(1) })
    }

    @Test
    fun fixMyMistakesKeepsItsFixedList() {
        val items = SessionBuilder.reviewSession(SessionBuilder.reviewableIDs(false).take(5).toList(), includePro = false)
        val (next, index) = advancedRun(items, 2, isGenerated = false) { error("Review never tops up") }
        assertEquals(items, next)
        assertEquals(3, index)
    }
}
