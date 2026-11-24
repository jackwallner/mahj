package com.jackwallner.mahj

import com.jackwallner.mahj.model.Suit
import com.jackwallner.mahj.model.Tile
import com.jackwallner.mahj.ui.screens.PassPicker
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/** The Charleston pass picker says why a tap did nothing instead of ignoring it. */
class PassPickerTest {
    private val rack = listOf(
        Tile.Suited(1, Suit.CRAK), Tile.Suited(2, Suit.BAM), Tile.Suited(3, Suit.DOT),
        Tile.Joker, Tile.Flower,
    )

    @Test
    fun aJokerIsRefusedWithTheRule() {
        val tap = PassPicker.tap(emptyList(), rack, 3)
        assertEquals(emptyList<Int>(), tap.selected)
        assertEquals(PassPicker.JOKER_REFUSAL, tap.refusal)
    }

    @Test
    fun aFourthTileIsRefusedUntilOneIsTakenBack() {
        val full = PassPicker.tap(listOf(0, 1, 2), rack, 4)
        assertEquals(listOf(0, 1, 2), full.selected)
        assertEquals(PassPicker.FULL_REFUSAL, full.refusal)

        val back = PassPicker.tap(listOf(0, 1, 2), rack, 1)
        assertEquals(listOf(0, 2), back.selected)
        assertNull("A tap that changes the pass clears the refusal", back.refusal)
    }

    @Test
    fun anOrdinaryTapAddsTheTile() {
        val tap = PassPicker.tap(listOf(0), rack, 4)
        assertEquals(listOf(0, 4), tap.selected)
        assertNull(tap.refusal)
    }
}
