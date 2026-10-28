package com.jackwallner.mahj

import com.jackwallner.mahj.content.EndlessPractice
import com.jackwallner.mahj.content.PracticeSkill
import com.jackwallner.mahj.content.SessionBuilder
import com.jackwallner.mahj.data.QuickItemState
import org.junit.Assert.assertEquals
import org.junit.Test

class QuickItemStateTest {
    @Test
    fun recreationPreservesAllAuthoredAnswersAndCoaching() {
        val items = listOf("tile-room", "card-room", "charleston-room", "table-room", "pro-tables")
            .flatMap { SessionBuilder.choiceItems(it, true) }.map(SessionBuilder::prepared)
        assertEquals(items, QuickItemState.decode(QuickItemState.encode(items)))
    }

    @Test
    fun recreationPreservesGeneratedRacksAndTrackingIdentity() {
        val items = PracticeSkill.endlessCases.flatMap { EndlessPractice.items(it, 8) }
        assertEquals(items, QuickItemState.decode(QuickItemState.encode(items)))
        assertEquals(emptyList<Any>(), QuickItemState.decode(QuickItemState.encode(emptyList())))
    }
}
