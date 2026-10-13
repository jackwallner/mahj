package com.jackwallner.mahj

import com.jackwallner.mahj.content.HandPlayEngine
import com.jackwallner.mahj.model.Dragon
import com.jackwallner.mahj.model.HandCategory
import com.jackwallner.mahj.model.Suit
import com.jackwallner.mahj.model.Tile
import com.jackwallner.mahj.model.Wind
import org.junit.Assert.assertEquals
import org.junit.Test

class HandPlayEngineTest {
    private fun c(rank: Int) = Tile.Suited(rank, Suit.CRAK)
    private fun b(rank: Int) = Tile.Suited(rank, Suit.BAM)
    private fun d(rank: Int) = Tile.Suited(rank, Suit.DOT)

    /** iOS `testEquallyUselessRunDiscardsAllGradeCorrect`: the same rack, the same answer. */
    @Test
    fun equallyUselessRunDiscardsAllGradeCorrect() {
        val rack = listOf(
            c(1), c(5), c(5), c(6), c(7), c(8), c(8), b(3), b(4), b(5), d(3),
            Tile.DragonTile(Dragon.RED), Tile.WindTile(Wind.WEST), Tile.WindTile(Wind.NORTH),
        )
        assertEquals(5..8, HandPlayEngine.bestRunRange(rack))
        val expected = setOf(
            c(1), b(3), b(4), d(3), Tile.DragonTile(Dragon.RED), Tile.WindTile(Wind.WEST), Tile.WindTile(Wind.NORTH),
        )
        assertEquals(expected, HandPlayEngine.bestDiscards(rack, HandCategory.CONSECUTIVE_RUN))
    }
}
