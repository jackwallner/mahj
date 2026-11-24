package com.jackwallner.mahj

import com.jackwallner.mahj.ui.components.missedOnTallQuestion
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** A miss on a question taller than most of the screen repeats its rack above the note. */
class MissedRackRecapTest {
    @Test
    fun onlyATallMissedRackQuestionRepeatsTheRack() {
        assertTrue(missedOnTallQuestion(missed = true, tileCount = 13, questionHeight = 1200, viewportHeight = 1600))
        assertFalse("A short question keeps its rack in view", missedOnTallQuestion(true, 13, 600, 1600))
        assertFalse("A right answer needs no recap", missedOnTallQuestion(false, 13, 1200, 1600))
        assertFalse("No rack, nothing to repeat", missedOnTallQuestion(true, 0, 1200, 1600))
        assertFalse("Not measured yet", missedOnTallQuestion(true, 13, 1200, 0))
    }
}
