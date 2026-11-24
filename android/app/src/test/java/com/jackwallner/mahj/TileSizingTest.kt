package com.jackwallner.mahj

import com.jackwallner.mahj.ui.components.TileSizing
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/** Port of iOS `TileRackFitTests`: racks wrap to their width, rows stay balanced, tiles grow with the font size. */
class TileSizingTest {
    private fun width(layout: TileSizing.Arrangement, tile: Float) =
        layout.rows.maxOf { it * tile + (it - 1) * layout.gap }

    @Test
    fun aRackFitsTheWidthItIsOffered() {
        // A 360dp phone inside padding, narrower cards, and the iOS zoomed widths.
        for (offered in listOf(200f, 236f, 268f, 288f, 320f, 328f)) {
            for ((count, tile) in listOf(13 to 44f, 14 to 40f, 13 to 36f)) {
                val layout = TileSizing.arrangement(count, tile, offered)
                assertTrue("$count tiles at ${tile}dp in ${offered}dp", width(layout, tile) <= offered + 0.5f)
                assertEquals(count, layout.rows.sum())
            }
        }
    }

    @Test
    fun aRackThatFitsKeepsItsDesign() {
        val layout = TileSizing.arrangement(13, 44f, 400f)
        assertEquals(listOf(7, 6), layout.rows)
        assertEquals(6f, layout.gap)
        assertEquals(TileSizing.arrangement(13, 44f, null), layout)
        assertEquals(listOf(4, 4), TileSizing.arrangement(8, 44f, 400f).rows)
    }

    /** Seven 44dp tiles need 344dp with the design's gaps; a 360dp phone gives 328dp. */
    @Test
    fun aSmallPhoneKeepsSevenTilesWithATighterGap() {
        val layout = TileSizing.arrangement(13, 44f, 328f)
        assertEquals(listOf(7, 6), layout.rows)
        assertTrue(layout.gap >= TileSizing.MINIMUM_SPACING && layout.gap < 6f)
    }

    @Test
    fun aNarrowRackWrapsRatherThanShrinkingItsTiles() {
        assertEquals("Five a row: 5, 4, 4", listOf(5, 4, 4), TileSizing.arrangement(13, 44f, 268f).rows)
        assertEquals("Never 4, 4, 4 and a lone tile", listOf(4, 3, 3, 3), TileSizing.rows(13, 4))
    }

    @Test
    fun tilesGrowWithTheFontSizeAndStopAtTheCap() {
        val steps = listOf(0.85f, 1f, 1.15f, 1.3f, 1.5f, 1.8f, 2f)
        val scales = steps.map(TileSizing::scale)
        assertEquals("Never shrinks as text grows", scales.sorted(), scales)
        assertEquals(listOf(1f, 1f, 1.1f, 1.2f, 1.3f, 1.4f, 1.4f), scales)
        assertEquals(61.6f, TileSizing.scaled(44f, 2f), 0.01f)
        assertEquals(TileSizing.MAXIMUM_WIDTH, TileSizing.scaled(54f, 2f))
        assertEquals(44f, TileSizing.scaled(44f, 0.85f))
    }

    @Test
    fun aLargeTextRackStillFitsANarrowQuestion() {
        for (fontScale in listOf(1f, 1.15f, 1.3f, 1.5f, 1.8f, 2f)) {
            val tile = TileSizing.scaled(44f, fontScale)
            val layout = TileSizing.arrangement(13, tile, 268f)
            assertTrue("$fontScale", width(layout, tile) <= 268.5f)
            assertTrue("No lone tile at $fontScale", layout.rows.size <= 4 && layout.rows.min() >= 3)
        }
        assertEquals(listOf(4, 3, 3, 3), TileSizing.arrangement(13, TileSizing.scaled(44f, 2f), 268f).rows)
    }
}
