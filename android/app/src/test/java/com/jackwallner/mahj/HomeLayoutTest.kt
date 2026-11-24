package com.jackwallner.mahj

import com.jackwallner.mahj.ui.screens.TrainingCarousel
import kotlin.math.floor
import org.junit.Assert.assertTrue
import org.junit.Test

/** Port of iOS `HomeLayoutTests`: the Training row always ends partway into a tile, so it reads as scrollable. */
class HomeLayoutTest {
    @Test
    fun theTrainingRowAlwaysCutsATile() {
        for (row in 300..640 step 4) {
            val tile = TrainingCarousel.tileWidth(row.toFloat())
            val shown = (row - TrainingCarousel.LEADING_INSET + TrainingCarousel.SPACING) / (tile + TrainingCarousel.SPACING)
            val cut = shown - floor(shown)
            assertTrue("A ${row}dp row cuts its last tile at $cut", cut in 0.25f..0.6f)
            assertTrue("A ${row}dp row keeps tiles at ${tile}dp", tile >= TrainingCarousel.MINIMUM_TILE_WIDTH)
        }
    }
}
